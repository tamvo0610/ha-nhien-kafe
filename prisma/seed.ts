import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

// Use DIRECT_URL (Session Pooler) for seeding - supports prepared statements
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DIRECT_URL,
    },
  },
});

async function main() {
  console.log('🌱 Starting seed...');

  // Clean existing data (dev only)
  if (process.env.NODE_ENV === 'development') {
    console.log('🧹 Cleaning existing data...');
    await prisma.orderEvent.deleteMany();
    await prisma.orderItemOption.deleteMany();
    await prisma.orderItem.deleteMany();
    await prisma.paymentTransaction.deleteMany();
    await prisma.payment.deleteMany();
    await prisma.order.deleteMany();
    await prisma.orderRequestItemOption.deleteMany();
    await prisma.orderRequestItem.deleteMany();
    await prisma.orderRequest.deleteMany();
    await prisma.customerNotification.deleteMany();
    await prisma.customerSession.deleteMany();
    await prisma.diningSession.deleteMany();
    await prisma.tableQrToken.deleteMany();
    await prisma.table.deleteMany();
    await prisma.productOption.deleteMany();
    await prisma.productOptionGroup.deleteMany();
    await prisma.product.deleteMany();
    await prisma.category.deleteMany();
    await prisma.storeSetting.deleteMany();
    await prisma.user.deleteMany();
  }

  // ============================================================================
  // Users
  // ============================================================================
  console.log('👤 Creating users...');

  const adminUser = await prisma.user.create({
    data: {
      name: 'Admin',
      email: 'admin@nhien.local',
      passwordHash: await bcrypt.hash('admin123', 10),
      role: 'ADMIN',
      isActive: true,
    },
  });

  const staffUser = await prisma.user.create({
    data: {
      name: 'Nhân Viên',
      email: 'staff@nhien.local',
      passwordHash: await bcrypt.hash('staff123', 10),
      role: 'STAFF',
      isActive: true,
    },
  });

  console.log(`✅ Created admin: ${adminUser.email}`);
  console.log(`✅ Created staff: ${staffUser.email}`);

  // ============================================================================
  // Categories
  // ============================================================================
  console.log('📂 Creating categories...');

  const categories = await Promise.all([
    prisma.category.create({
      data: {
        name: 'Mì trộn',
        slug: 'mi-tron',
        description: 'Các món mì trộn đặc biệt',
        sortOrder: 1,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Cơm chiên',
        slug: 'com-chien',
        description: 'Cơm chiên thơm ngon',
        sortOrder: 2,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Ăn vặt',
        slug: 'an-vat',
        description: 'Các món ăn vặt hấp dẫn',
        sortOrder: 3,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Cá viên',
        slug: 'ca-vien',
        description: 'Cá viên chiên giòn',
        sortOrder: 4,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Trà/Nước',
        slug: 'tra-nuoc',
        description: 'Đồ uống giải khát',
        sortOrder: 5,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Trà sữa',
        slug: 'tra-sua',
        description: 'Trà sữa các loại',
        sortOrder: 6,
        isActive: true,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Cà phê',
        slug: 'ca-phe',
        description: 'Cà phê rang xay',
        sortOrder: 7,
        isActive: true,
      },
    }),
  ]);

  console.log(`✅ Created ${categories.length} categories`);

  // ============================================================================
  // Products with Options
  // ============================================================================
  console.log('🍜 Creating products...');

  // Mì trộn
  const miTron = await prisma.product.create({
    data: {
      categoryId: categories[0].id,
      name: 'Mì trộn trứng xá xíu',
      slug: 'mi-tron-trung-xa-xiu',
      description: 'Mì trộn thơm ngon với trứng và xá xíu',
      price: 35000,
      costPrice: 20000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Add option groups for Mì trộn
  const miTronSizeGroup = await prisma.productOptionGroup.create({
    data: {
      productId: miTron.id,
      name: 'Kích cỡ',
      selectionType: 'SINGLE',
      isRequired: true,
      sortOrder: 1,
    },
  });

  await Promise.all([
    prisma.productOption.create({
      data: {
        groupId: miTronSizeGroup.id,
        name: 'Thường',
        additionalPrice: 0,
        sortOrder: 1,
      },
    }),
    prisma.productOption.create({
      data: {
        groupId: miTronSizeGroup.id,
        name: 'To',
        additionalPrice: 5000,
        sortOrder: 2,
      },
    }),
  ]);

  const miTronToppingGroup = await prisma.productOptionGroup.create({
    data: {
      productId: miTron.id,
      name: 'Topping',
      selectionType: 'MULTIPLE',
      isRequired: false,
      maxSelections: 3,
      sortOrder: 2,
    },
  });

  await Promise.all([
    prisma.productOption.create({
      data: {
        groupId: miTronToppingGroup.id,
        name: 'Thêm trứng',
        additionalPrice: 5000,
        sortOrder: 1,
      },
    }),
    prisma.productOption.create({
      data: {
        groupId: miTronToppingGroup.id,
        name: 'Thêm xá xíu',
        additionalPrice: 10000,
        sortOrder: 2,
      },
    }),
    prisma.productOption.create({
      data: {
        groupId: miTronToppingGroup.id,
        name: 'Thêm xúc xích',
        additionalPrice: 7000,
        sortOrder: 3,
      },
    }),
  ]);

  // Cơm chiên
  await prisma.product.create({
    data: {
      categoryId: categories[1].id,
      name: 'Cơm chiên xá xíu',
      slug: 'com-chien-xa-xiu',
      description: 'Cơm chiên thơm ngon với xá xíu',
      price: 40000,
      costPrice: 22000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Ăn vặt
  await prisma.product.create({
    data: {
      categoryId: categories[2].id,
      name: 'Khoai tây chiên',
      slug: 'khoai-tay-chien',
      description: 'Khoai tây chiên giòn rụm',
      price: 25000,
      costPrice: 12000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Cá viên
  await prisma.product.create({
    data: {
      categoryId: categories[3].id,
      name: 'Cá viên chiên',
      slug: 'ca-vien-chien',
      description: 'Cá viên chiên giòn',
      price: 20000,
      costPrice: 10000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Trà/Nước
  const traDao = await prisma.product.create({
    data: {
      categoryId: categories[4].id,
      name: 'Trà đào',
      slug: 'tra-dao',
      description: 'Trà đào mát lạnh',
      price: 25000,
      costPrice: 10000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Add ice level option
  const iceGroup = await prisma.productOptionGroup.create({
    data: {
      productId: traDao.id,
      name: 'Đá',
      selectionType: 'SINGLE',
      isRequired: true,
      sortOrder: 1,
    },
  });

  await Promise.all([
    prisma.productOption.create({
      data: { groupId: iceGroup.id, name: 'Đá thường', additionalPrice: 0, sortOrder: 1 },
    }),
    prisma.productOption.create({
      data: { groupId: iceGroup.id, name: 'Ít đá', additionalPrice: 0, sortOrder: 2 },
    }),
    prisma.productOption.create({
      data: { groupId: iceGroup.id, name: 'Không đá', additionalPrice: 0, sortOrder: 3 },
    }),
  ]);

  // Trà sữa
  await prisma.product.create({
    data: {
      categoryId: categories[5].id,
      name: 'Trà sữa truyền thống',
      slug: 'tra-sua-truyen-thong',
      description: 'Trà sữa đậm vị',
      price: 25000,
      costPrice: 12000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  // Cà phê
  await prisma.product.create({
    data: {
      categoryId: categories[6].id,
      name: 'Cà phê đen',
      slug: 'ca-phe-den',
      description: 'Cà phê đen nguyên chất',
      price: 20000,
      costPrice: 8000,
      isActive: true,
      isAvailable: true,
      sortOrder: 1,
    },
  });

  console.log(`✅ Created products with options`);

  // ============================================================================
  // Tables
  // ============================================================================
  console.log('🪑 Creating tables...');

  const tables = await Promise.all([
    prisma.table.create({
      data: { code: 'T01', name: 'Bàn 01', capacity: 4, isActive: true },
    }),
    prisma.table.create({
      data: { code: 'T02', name: 'Bàn 02', capacity: 4, isActive: true },
    }),
    prisma.table.create({
      data: { code: 'T03', name: 'Bàn 03', capacity: 6, isActive: true },
    }),
    prisma.table.create({
      data: { code: 'T04', name: 'Bàn 04', capacity: 2, isActive: true },
    }),
    prisma.table.create({
      data: { code: 'T05', name: 'Bàn 05', capacity: 8, isActive: true },
    }),
  ]);

  // Create QR tokens for tables
  for (const table of tables) {
    const tokenHash = await bcrypt.hash(`table-${table.code}-${Date.now()}`, 10);
    await prisma.tableQrToken.create({
      data: {
        tableId: table.id,
        tokenHash,
        isActive: true,
      },
    });
  }

  console.log(`✅ Created ${tables.length} tables with QR tokens`);

  // ============================================================================
  // Store Settings
  // ============================================================================
  console.log('⚙️ Creating store settings...');

  await prisma.storeSetting.create({
    data: {
      key: 'store_info',
      value: {
        name: 'Nhiên',
        address: 'Địa chỉ quán',
        phone: '0123456789',
        currency: 'VND',
      },
    },
  });

  await prisma.storeSetting.create({
    data: {
      key: 'payment_bank',
      value: {
        bankName: '',
        accountNumber: '',
        accountHolder: '',
      },
    },
  });

  console.log(`✅ Created store settings`);

  console.log('');
  console.log('✨ Seed completed successfully!');
  console.log('');
  console.log('📝 Development credentials:');
  console.log('   Admin: admin@nhien.local / admin123');
  console.log('   Staff: staff@nhien.local / staff123');
  console.log('');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
