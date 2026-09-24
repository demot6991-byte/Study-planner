import { Module } from '@nestjs/common';
import { SeedController } from './seed.controller';
import { SeedService } from './seed.service';
import { SupabaseService } from '../common/supabase.service';

@Module({
  controllers: [SeedController],
  providers: [SeedService, SupabaseService],
  exports: [SupabaseService],
})
export class SeedModule {}
