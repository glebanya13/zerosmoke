import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Devices + subscription checkout (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let jwt: JwtService;
  let config: ConfigService;
  let userId: string;
  let accessToken: string;
  let adminKey: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
    config = app.get(ConfigService);
    adminKey = config.get<string>('ADMIN_API_KEY') ?? 'change-me';

    const user = await prisma.user.create({
      data: {
        email: `devices-e2e-${Date.now()}@example.com`,
        role: 'CHILD',
        name: 'Push User',
        age: 12,
        isFemale: false,
        avatarIndex: 0,
        referralCode: `E2E${Date.now()}`,
      },
    });
    userId = user.id;
    accessToken = jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      {
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: '1h',
      },
    );
  });

  afterAll(async () => {
    await prisma.devicePushToken.deleteMany({ where: { userId } });
    await prisma.subscription.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${accessToken}` });

  it('registers a push token', async () => {
    const res = await request(app.getHttpServer())
      .post('/devices/push-token')
      .set(auth())
      .send({ token: 'test-device-token-abcdef', platform: 'android' })
      .expect(201);

    expect(res.body.token).toBe('test-device-token-abcdef');
    expect(res.body.platform).toBe('android');
  });

  it('returns website checkout url', async () => {
    const res = await request(app.getHttpServer())
      .get('/subscription/checkout-url')
      .query({ planId: '1m' })
      .set(auth())
      .expect(200);

    expect(res.body.url).toContain('planId=1m');
    expect(res.body.url).toContain(`userId=${userId}`);
  });

  it('activates subscription from website with admin key', async () => {
    const res = await request(app.getHttpServer())
      .post('/subscription/activate')
      .set({ 'x-admin-key': adminKey })
      .send({ userId, planId: '1m', paymentRef: 'web-pay-1' })
      .expect(201);

    expect(res.body.status).toBe('ACTIVE');
    expect(res.body.provider).toBe('WEB');

    const active = await request(app.getHttpServer())
      .get('/subscription/active')
      .set(auth())
      .expect(200);
    expect(active.body.active).toBe(true);
  });
});
