import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AnswerQuestionDto } from './dto/answer-question.dto';
import { AssignTestDto } from './dto/assign-test.dto';
import type { User } from '../../generated/prisma/client';

@Controller('content')
@UseGuards(JwtAuthGuard)
export class ContentController {
  constructor(private readonly content: ContentService) {}

  @Get('sections')
  sections(@CurrentUser() user: User) {
    return this.content.sections(user.age);
  }

  @Get('sections/:id')
  section(@Param('id') id: string, @CurrentUser() user: User) {
    return this.content.section(id, user.age);
  }

  @Get('tests')
  tests(@CurrentUser() user: User) {
    return this.content.tests(user.age, user.id);
  }

  @Get('tests/:id')
  test(@Param('id') id: string, @CurrentUser() user: User) {
    return this.content.test(id, user.age);
  }

  @Get('guide')
  guide() {
    return this.content.guide();
  }

  @Get('assignments')
  assignments(@CurrentUser() user: User) {
    return this.content.myAssignments(user);
  }

  @Post('assignments')
  assign(@CurrentUser() user: User, @Body() dto: AssignTestDto) {
    return this.content.assignTest(user, dto);
  }

  @Post('tests/:id/attempt')
  startAttempt(@Param('id') id: string, @CurrentUser() user: User) {
    return this.content.startAttempt(id, user.id, user.age);
  }

  @Post('attempts/:attemptId/answer')
  answer(
    @Param('attemptId') attemptId: string,
    @CurrentUser() user: User,
    @Body() dto: AnswerQuestionDto,
  ) {
    return this.content.answer(attemptId, user.id, dto);
  }

  @Post('attempts/:attemptId/complete')
  complete(@Param('attemptId') attemptId: string, @CurrentUser() user: User) {
    return this.content.complete(attemptId, user.id);
  }
}
