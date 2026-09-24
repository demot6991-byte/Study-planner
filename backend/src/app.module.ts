import { Module, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { DataModule } from './data/data.module';
import { CrudModule } from './crud/crud.module';
import { SeedModule } from './seed/seed.module';
import { AuthMiddleware } from './common/auth.middleware';
import { JwtService } from './common/jwt.service';
import { SupabaseService } from './common/supabase.service';
import { HealthController } from './common/health.controller';

@Module({
  imports: [AuthModule, DataModule, CrudModule, SeedModule],
  controllers: [HealthController],
  providers: [JwtService, SupabaseService],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .exclude(
        { path: 'auth/signup', method: RequestMethod.POST },
        { path: 'auth/signin', method: RequestMethod.POST },
        { path: 'auth/signout', method: RequestMethod.POST },
        { path: 'auth/refresh', method: RequestMethod.POST },
        { path: 'auth/session', method: RequestMethod.GET },
        { path: 'seed/templates', method: RequestMethod.GET },
        { path: 'seed/template', method: RequestMethod.GET },
        { path: 'health', method: RequestMethod.GET },
      )
      .forRoutes('data', 'seed', 'auth/onboarding', ':table');
  }
}
