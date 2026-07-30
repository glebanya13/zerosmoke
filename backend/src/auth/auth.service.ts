import {
  ConflictException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createHash } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import type { MailService } from '../mail/mail.service';
import { MAIL_SERVICE } from '../mail/mail.service';
import { OtpPurpose } from '../../generated/prisma/enums';
import type { User } from '../../generated/prisma/client';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { CompleteRegistrationDto } from './dto/complete-registration.dto';
import { RefreshDto } from './dto/refresh.dto';
import { parseDurationMs } from './duration.util';
import type { StringValue } from 'ms';

interface RegistrationTokenPayload {
  email: string;
}

interface RefreshTokenPayload {
  sub: string;
  jti: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    @Inject(MAIL_SERVICE) private readonly mailService: MailService,
  ) {}

  private hashSecret(value: string): string {
    return createHash('sha256').update(value).digest('hex');
  }

  private generateOtpCode(): string {
    // TODO: revert to random once Unisender Go is wired up
    return '1234';
  }

  async requestOtp(dto: RequestOtpDto): Promise<{ message: string }> {
    const existingUser = await this.prisma.user.findUnique({ where: { email: dto.email } });

    if (dto.purpose === OtpPurpose.REGISTER && existingUser) {
      throw new ConflictException('An account with this email already exists');
    }
    if (dto.purpose === OtpPurpose.LOGIN && !existingUser) {
      throw new NotFoundException('No account found for this email');
    }

    const cooldownSeconds = this.config.getOrThrow<number>('OTP_REQUEST_COOLDOWN_SECONDS');
    const lastOtp = await this.prisma.otpCode.findFirst({
      where: { email: dto.email, purpose: dto.purpose },
      orderBy: { createdAt: 'desc' },
    });
    if (lastOtp && Date.now() - lastOtp.createdAt.getTime() < cooldownSeconds * 1000) {
      throw new HttpException('Please wait before requesting another code', HttpStatus.TOO_MANY_REQUESTS);
    }

    const code = this.generateOtpCode();
    const ttlMinutes = this.config.getOrThrow<number>('OTP_TTL_MINUTES');
    await this.prisma.otpCode.create({
      data: {
        email: dto.email,
        purpose: dto.purpose,
        codeHash: this.hashSecret(code),
        expiresAt: new Date(Date.now() + ttlMinutes * 60_000),
      },
    });

    await this.mailService.sendOtpCode(dto.email, code);

    return { message: 'Verification code sent' };
  }

  async verifyOtp(
    dto: VerifyOtpDto,
  ): Promise<
    | { purpose: 'REGISTER'; registrationToken: string }
    | { purpose: 'LOGIN'; accessToken: string; refreshToken: string; user: User }
  > {
    const otp = await this.prisma.otpCode.findFirst({
      where: {
        email: dto.email,
        purpose: dto.purpose,
        consumedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp || otp.codeHash !== this.hashSecret(dto.code)) {
      throw new UnauthorizedException('Invalid or expired code');
    }

    await this.prisma.otpCode.update({
      where: { id: otp.id },
      data: { consumedAt: new Date() },
    });

    if (dto.purpose === OtpPurpose.REGISTER) {
      const payload: RegistrationTokenPayload = { email: dto.email };
      const registrationToken = this.jwtService.sign(payload, {
        secret: this.config.getOrThrow<string>('REGISTRATION_TOKEN_SECRET'),
        expiresIn: this.config.getOrThrow<StringValue>('REGISTRATION_TOKEN_TTL'),
      });
      return { purpose: 'REGISTER', registrationToken };
    }

    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) {
      throw new NotFoundException('No account found for this email');
    }
    const tokens = await this.issueTokens(user);
    return { purpose: 'LOGIN', user, ...tokens };
  }

  async completeRegistration(
    dto: CompleteRegistrationDto,
  ): Promise<{ accessToken: string; refreshToken: string; user: User }> {
    let payload: RegistrationTokenPayload;
    try {
      payload = this.jwtService.verify<RegistrationTokenPayload>(dto.registrationToken, {
        secret: this.config.getOrThrow<string>('REGISTRATION_TOKEN_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired registration token');
    }

    const existingUser = await this.prisma.user.findUnique({ where: { email: payload.email } });
    if (existingUser) {
      throw new ConflictException('An account with this email already exists');
    }

    const user = await this.prisma.user.create({
      data: {
        email: payload.email,
        role: dto.role,
        name: dto.name,
        age: dto.age,
        isFemale: dto.isFemale,
        avatarIndex: dto.avatarIndex,
        phone: dto.phone,
      },
    });

    const tokens = await this.issueTokens(user);
    return { user, ...tokens };
  }

  async refresh(dto: RefreshDto): Promise<{ accessToken: string; refreshToken: string }> {
    let payload: RefreshTokenPayload;
    try {
      payload = this.jwtService.verify<RefreshTokenPayload>(dto.refreshToken, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const stored = await this.prisma.refreshToken.findUnique({ where: { id: payload.jti } });
    if (
      !stored ||
      stored.revokedAt ||
      stored.expiresAt.getTime() < Date.now() ||
      stored.tokenHash !== this.hashSecret(dto.refreshToken)
    ) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = await this.prisma.user.findUnique({ where: { id: stored.userId } });
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });

    return this.issueTokens(user);
  }

  async logout(userId: string, refreshToken: string): Promise<{ message: string }> {
    let payload: RefreshTokenPayload;
    try {
      payload = this.jwtService.verify<RefreshTokenPayload>(refreshToken, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      return { message: 'Logged out' };
    }

    if (payload.sub !== userId) {
      throw new UnauthorizedException('Token does not belong to current user');
    }

    await this.prisma.refreshToken.updateMany({
      where: { id: payload.jti, userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    return { message: 'Logged out' };
  }

  private async issueTokens(user: User): Promise<{ accessToken: string; refreshToken: string }> {
    const accessToken = this.jwtService.sign(
      { sub: user.id, email: user.email, role: user.role },
      {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: this.config.getOrThrow<StringValue>('JWT_ACCESS_TTL'),
      },
    );

    const refreshTtl = this.config.getOrThrow<StringValue>('JWT_REFRESH_TTL');
    const refreshTokenRow = await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: '',
        expiresAt: new Date(Date.now() + parseDurationMs(refreshTtl)),
      },
    });

    const refreshToken = this.jwtService.sign(
      { sub: user.id, jti: refreshTokenRow.id },
      {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: refreshTtl,
      },
    );

    await this.prisma.refreshToken.update({
      where: { id: refreshTokenRow.id },
      data: { tokenHash: this.hashSecret(refreshToken) },
    });

    return { accessToken, refreshToken };
  }
}
