import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL!,
});

const prisma = new PrismaClient({ adapter });

try {
  await prisma.$queryRaw`SELECT current_database(), current_schema()`;
  console.log("Database connection successful!");
} catch (error) {
  console.error("Database connection failed:", error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
