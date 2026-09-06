import { Module } from '@nestjs/common';
import { QuitService } from './quit.service';
import { QuitController } from './quit.controller';

@Module({
  controllers: [QuitController],
  providers: [QuitService],
  exports: [QuitService],
})
export class QuitModule {}
