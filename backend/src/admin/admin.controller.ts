import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminKeyGuard } from './admin-key.guard';
import { AdminService } from './admin.service';
import { CreateAdminTestDto } from './dto/create-admin-test.dto';
import { UpdateAdminTestDto } from './dto/update-admin-test.dto';
import { UpdateAdminGuideDto } from './dto/update-admin-guide.dto';
import {
  CreateAdminQuestionDto,
  MoveAdminQuestionDto,
  UpdateAdminQuestionDto,
} from './dto/admin-question.dto';
import { MoveAdminEntityDto } from './dto/move-admin-entity.dto';

@Controller('admin')
@UseGuards(AdminKeyGuard)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('users')
  users(
    @Query('search') search?: string,
    @Query('role') role?: 'PARENT' | 'CHILD' | 'ADULT',
  ) {
    return this.admin.users(search, role);
  }

  @Get('links')
  links() {
    return this.admin.links();
  }

  @Get('tests')
  tests() {
    return this.admin.tests();
  }

  @Get('tests/:id')
  test(@Param('id') id: string) {
    return this.admin.test(id);
  }

  @Get('content/summary')
  contentSummary() {
    return this.admin.contentSummary();
  }

  @Get('sections')
  sections() {
    return this.admin.sections();
  }

  @Get('guides')
  guides() {
    return this.admin.guides();
  }

  @Get('guides/:slug')
  guide(@Param('slug') slug: string) {
    return this.admin.guide(slug);
  }

  @Patch('guides/:slug')
  updateGuide(
    @Param('slug') slug: string,
    @Body() dto: UpdateAdminGuideDto,
  ) {
    return this.admin.updateGuide(slug, dto);
  }

  @Post('tests')
  createTest(@Body() dto: CreateAdminTestDto) {
    return this.admin.createTest(dto);
  }

  @Post('tests/:id/move')
  moveTest(@Param('id') id: string, @Body() dto: MoveAdminEntityDto) {
    return this.admin.moveTest(id, dto.direction);
  }

  @Post('sections/:id/move')
  moveSection(@Param('id') id: string, @Body() dto: MoveAdminEntityDto) {
    return this.admin.moveSection(id, dto.direction);
  }

  @Patch('tests/:id')
  updateTest(@Param('id') id: string, @Body() dto: UpdateAdminTestDto) {
    return this.admin.updateTest(id, dto);
  }

  @Delete('tests/:id')
  deleteTest(@Param('id') id: string) {
    return this.admin.deleteTest(id);
  }

  @Post('tests/:id/questions')
  createQuestion(@Param('id') id: string, @Body() dto: CreateAdminQuestionDto) {
    return this.admin.createQuestion(id, dto);
  }

  @Patch('tests/:testId/questions/:questionId')
  updateQuestion(
    @Param('testId') testId: string,
    @Param('questionId') questionId: string,
    @Body() dto: UpdateAdminQuestionDto,
  ) {
    return this.admin.updateQuestion(testId, questionId, dto);
  }

  @Delete('tests/:testId/questions/:questionId')
  deleteQuestion(
    @Param('testId') testId: string,
    @Param('questionId') questionId: string,
  ) {
    return this.admin.deleteQuestion(testId, questionId);
  }

  @Post('tests/:testId/questions/:questionId/move')
  moveQuestion(
    @Param('testId') testId: string,
    @Param('questionId') questionId: string,
    @Body() dto: MoveAdminQuestionDto,
  ) {
    return this.admin.moveQuestion(testId, questionId, dto.direction);
  }
}
