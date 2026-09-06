import { createHash } from 'node:crypto';
import { HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import type { PrismaService } from '../prisma/prisma.service';
import type { MailService } from '../mail/mail.service';
import type { ReferralsService } from '../referrals/referrals.service';
import { OtpPurpose } from '../../generated/prisma/enums';

describe('AuthService OTP', () => {
  const hashSecret = (value: string) => createHash('sha256').update(value).digest('hex');

  function buildService(overrides?: {
    lastOtp?: {
      id: string;
      email: string;
      purpose: typeof OtpPurpose.REGISTER;
      codeHash: string;
      expiresAt: Date;
      consumedAt: Date | null;
      createdAt: Date;
    } | null;
    user?: { id: string; email: string } | null;
  }) {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue(overrides?.user ?? null),
      },
      otpCode: {
        findFirst: jest.fn().mockResolvedValue(overrides?.lastOtp ?? null),
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        create: jest.fn().mockResolvedValue({ id: 'otp-new' }),
        update: jest.fn(),
      },
    } as unknown as PrismaService;

    const config = {
      getOrThrow: jest.fn((key: string) => {
        const values: Record<string, number | string> = {
          OTP_REQUEST_COOLDOWN_SECONDS: 30,
          OTP_TTL_MINUTES: 10,
          REGISTRATION_TOKEN_SECRET: 'reg-secret',
          REGISTRATION_TOKEN_TTL: '15m',
          JWT_ACCESS_SECRET: 'access',
          JWT_ACCESS_TTL: '15m',
          JWT_REFRESH_SECRET: 'refresh',
          JWT_REFRESH_TTL: '30d',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const jwtService = {
      sign: jest.fn().mockReturnValue('registration-token'),
    } as unknown as JwtService;

    const mailService = {
      sendOtpCode: jest.fn().mockResolvedValue(undefined),
    } as unknown as MailService;

    const referralsService = {
      generateReferralCode: jest.fn().mockReturnValue('FRIEND1'),
    } as unknown as ReferralsService;

    return {
      service: new AuthService(prisma, jwtService, config, mailService, referralsService),
      prisma,
      mailService,
    };
  }

  it('rejects login when the account does not exist', async () => {
    const { service } = buildService();
    await expect(
      service.requestOtp({ email: ' Parent@Example.com ', purpose: OtpPurpose.LOGIN }),
    ).rejects.toMatchObject({
      message: 'Аккаунт с этим e-mail не найден. Сначала создайте аккаунт.',
    });
  });

  it('allows a new OTP request when the previous code expired', async () => {
    const expiredOtp = {
      id: 'otp-1',
      email: 'parent@example.com',
      purpose: OtpPurpose.REGISTER,
      codeHash: hashSecret('1234'),
      expiresAt: new Date(Date.now() - 60_000),
      consumedAt: null,
      createdAt: new Date(),
    };
    const { service, prisma, mailService } = buildService({ lastOtp: expiredOtp });

    const result = await service.requestOtp({
      email: 'parent@example.com',
      purpose: OtpPurpose.REGISTER,
    });

    expect(result.message).toBe('Код отправлен на e-mail');
    expect(prisma.otpCode.updateMany).toHaveBeenCalled();
    expect(prisma.otpCode.create).toHaveBeenCalled();
    expect(mailService.sendOtpCode).toHaveBeenCalledWith(
      'parent@example.com',
      expect.stringMatching(/^\d{4}$/),
    );
  });

  it('blocks OTP resend while the previous code is still valid', async () => {
    const activeOtp = {
      id: 'otp-1',
      email: 'parent@example.com',
      purpose: OtpPurpose.REGISTER,
      codeHash: hashSecret('1234'),
      expiresAt: new Date(Date.now() + 5 * 60_000),
      consumedAt: null,
      createdAt: new Date(),
    };
    const { service } = buildService({ lastOtp: activeOtp });

    await expect(
      service.requestOtp({ email: 'parent@example.com', purpose: OtpPurpose.REGISTER }),
    ).rejects.toBeInstanceOf(HttpException);
  });

  it('returns a friendly message for an expired verification code', async () => {
    const { service } = buildService({ lastOtp: null });

    await expect(
      service.verifyOtp({
        email: 'parent@example.com',
        code: '1234',
        purpose: OtpPurpose.REGISTER,
      }),
    ).rejects.toMatchObject({
      message: 'Код истёк или уже использован. Вернитесь назад и запросите новый код.',
    });
  });

  it('returns a friendly message for a wrong verification code', async () => {
    const activeOtp = {
      id: 'otp-1',
      email: 'parent@example.com',
      purpose: OtpPurpose.REGISTER,
      codeHash: hashSecret('1234'),
      expiresAt: new Date(Date.now() + 5 * 60_000),
      consumedAt: null,
      createdAt: new Date(),
    };
    const { service } = buildService({ lastOtp: activeOtp });

    await expect(
      service.verifyOtp({
        email: 'parent@example.com',
        code: '9999',
        purpose: OtpPurpose.REGISTER,
      }),
    ).rejects.toMatchObject({
      message: 'Неверный код. Проверьте и попробуйте снова.',
    });
  });

  it('accepts a valid verification code', async () => {
    const activeOtp = {
      id: 'otp-1',
      email: 'parent@example.com',
      purpose: OtpPurpose.REGISTER,
      codeHash: hashSecret('1234'),
      expiresAt: new Date(Date.now() + 5 * 60_000),
      consumedAt: null,
      createdAt: new Date(),
    };
    const { service, prisma } = buildService({ lastOtp: activeOtp });

    const result = await service.verifyOtp({
      email: ' Parent@Example.com ',
      code: '1234',
      purpose: OtpPurpose.REGISTER,
    });

    expect(result).toEqual({
      purpose: 'REGISTER',
      registrationToken: 'registration-token',
    });
    expect(prisma.otpCode.update).toHaveBeenCalled();
  });
});
