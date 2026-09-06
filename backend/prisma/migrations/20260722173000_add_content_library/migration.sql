ALTER TABLE "Test"
ADD COLUMN "position" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "sourceFile" TEXT;

CREATE TABLE "ContentSection" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "audience" "TestAudience" NOT NULL,
    "position" INTEGER NOT NULL,
    "sourceFile" TEXT NOT NULL,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "ContentSection_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SectionQuestion" (
    "id" TEXT NOT NULL,
    "sectionId" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "material" TEXT,
    "text" TEXT NOT NULL,
    "options" JSONB NOT NULL,
    "correctOption" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "SectionQuestion_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "TestQuestion" (
    "id" TEXT NOT NULL,
    "testId" TEXT NOT NULL,
    "sectionId" TEXT,
    "position" INTEGER NOT NULL,
    "material" TEXT,
    "text" TEXT NOT NULL,
    "options" JSONB NOT NULL,
    "correctOption" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "TestQuestion_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Guide" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "sourceFile" TEXT NOT NULL,
    "pageCount" INTEGER NOT NULL,
    "content" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Guide_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Test_audience_position_idx" ON "Test"("audience", "position");
CREATE UNIQUE INDEX "ContentSection_audience_position_key" ON "ContentSection"("audience", "position");
CREATE INDEX "ContentSection_audience_idx" ON "ContentSection"("audience");
CREATE UNIQUE INDEX "SectionQuestion_sectionId_position_key" ON "SectionQuestion"("sectionId", "position");
CREATE UNIQUE INDEX "TestQuestion_testId_position_key" ON "TestQuestion"("testId", "position");
CREATE INDEX "TestQuestion_sectionId_idx" ON "TestQuestion"("sectionId");
CREATE UNIQUE INDEX "Guide_slug_key" ON "Guide"("slug");

ALTER TABLE "SectionQuestion" ADD CONSTRAINT "SectionQuestion_sectionId_fkey"
FOREIGN KEY ("sectionId") REFERENCES "ContentSection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "TestQuestion" ADD CONSTRAINT "TestQuestion_testId_fkey"
FOREIGN KEY ("testId") REFERENCES "Test"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "TestQuestion" ADD CONSTRAINT "TestQuestion_sectionId_fkey"
FOREIGN KEY ("sectionId") REFERENCES "ContentSection"("id") ON DELETE SET NULL ON UPDATE CASCADE;
