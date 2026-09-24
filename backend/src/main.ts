import 'reflect-metadata';
import dotenv from 'dotenv';

dotenv.config();

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors({
    origin: process.env.FRONTEND_URL || '*',
    credentials: true,
  });

  const port = parseInt(process.env.PORT || '3001', 10);
  await app.listen(port);
  Logger.log(`Backend server running on port ${port}`, 'Bootstrap');
}

bootstrap();
