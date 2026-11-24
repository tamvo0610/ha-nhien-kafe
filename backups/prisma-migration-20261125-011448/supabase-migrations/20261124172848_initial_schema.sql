-- Nhiên POS Database Migration
-- Generated from Prisma schema
-- Date: 2024-11-24

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- Enums
-- ============================================================================

CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'STAFF');
CREATE TYPE "SelectionType" AS ENUM ('SINGLE', 'MULTIPLE');
CREATE TYPE "CustomerSessionStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'REVOKED');
CREATE TYPE "DiningSessionStatus" AS ENUM ('ACTIVE', 'CLOSING', 'CLOSED');
CREATE TYPE "OrderRequestStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED');
CREATE TYPE "OrderType" AS ENUM ('DINE_IN', 'TAKEAWAY');
CREATE TYPE "OrderSource" AS ENUM ('STAFF', 'PUBLIC');
CREATE TYPE "OrderStatus" AS ENUM ('OPEN', 'COMPLETED', 'CANCELLED');
CREATE TYPE "PaymentStatus" AS ENUM ('UNPAID', 'PENDING', 'PARTIALLY_PAID', 'PAID', 'OVERPAID', 'REFUNDED');
CREATE TYPE "FulfillmentStatus" AS ENUM ('NOT_STARTED', 'PREPARING', 'READY', 'HANDED_OVER');
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'VIETQR');
CREATE TYPE "PaymentTransactionStatus" AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'EXPIRED', 'SUPERSEDED', 'RECONCILED');
CREATE TYPE "TransactionDirection" AS ENUM ('INBOUND', 'OUTBOUND');
CREATE TYPE "ActorType" AS ENUM ('STAFF', 'CUSTOMER', 'SYSTEM', 'PROVIDER');

-- ============================================================================
-- Tables
-- ============================================================================

-- Users
CREATE TABLE "users" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE,
    "passwordHash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'STAFF',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "users_email_idx" ON "users"("email");
CREATE INDEX "users_role_isActive_idx" ON "users"("role", "isActive");

-- Categories
CREATE TABLE "categories" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL UNIQUE,
    "description" TEXT,
    "imageUrl" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "categories_isActive_sortOrder_idx" ON "categories"("isActive", "sortOrder");
CREATE INDEX "categories_slug_idx" ON "categories"("slug");

-- Products
CREATE TABLE "products" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "categoryId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL UNIQUE,
    "description" TEXT,
    "imageUrl" TEXT,
    "price" INTEGER NOT NULL,
    "costPrice" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "products_categoryId_isActive_isAvailable_idx" ON "products"("categoryId", "isActive", "isAvailable");
CREATE INDEX "products_slug_idx" ON "products"("slug");

-- Product Option Groups
CREATE TABLE "product_option_groups" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "productId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "selectionType" "SelectionType" NOT NULL DEFAULT 'SINGLE',
    "isRequired" BOOLEAN NOT NULL DEFAULT false,
    "minSelections" INTEGER,
    "maxSelections" INTEGER,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "product_option_groups_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "product_option_groups_productId_isActive_idx" ON "product_option_groups"("productId", "isActive");

-- Product Options
CREATE TABLE "product_options" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "groupId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "additionalPrice" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "product_options_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "product_option_groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "product_options_groupId_isActive_idx" ON "product_options"("groupId", "isActive");

-- Customer Sessions
CREATE TABLE "customer_sessions" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "tokenHash" TEXT NOT NULL UNIQUE,
    "status" "CustomerSessionStatus" NOT NULL DEFAULT 'ACTIVE',
    "customerName" TEXT,
    "customerPhone" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "lastActiveAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "customer_sessions_tokenHash_idx" ON "customer_sessions"("tokenHash");
CREATE INDEX "customer_sessions_status_expiresAt_idx" ON "customer_sessions"("status", "expiresAt");

-- Tables
CREATE TABLE "tables" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "code" TEXT NOT NULL UNIQUE,
    "name" TEXT NOT NULL,
    "capacity" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "tables_code_idx" ON "tables"("code");
CREATE INDEX "tables_isActive_idx" ON "tables"("isActive");

-- Table QR Tokens
CREATE TABLE "table_qr_tokens" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "tableId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL UNIQUE,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "expiresAt" TIMESTAMP(3),
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "table_qr_tokens_tableId_fkey" FOREIGN KEY ("tableId") REFERENCES "tables"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "table_qr_tokens_tokenHash_idx" ON "table_qr_tokens"("tokenHash");
CREATE INDEX "table_qr_tokens_tableId_isActive_idx" ON "table_qr_tokens"("tableId", "isActive");

-- Dining Sessions
CREATE TABLE "dining_sessions" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "tableId" TEXT NOT NULL,
    "status" "DiningSessionStatus" NOT NULL DEFAULT 'ACTIVE',
    "openedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedAt" TIMESTAMP(3),
    "openedById" TEXT NOT NULL,
    "closedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "dining_sessions_tableId_fkey" FOREIGN KEY ("tableId") REFERENCES "tables"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "dining_sessions_openedById_fkey" FOREIGN KEY ("openedById") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "dining_sessions_closedById_fkey" FOREIGN KEY ("closedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "one_active_session_per_table" ON "dining_sessions"("tableId", "status") WHERE "status" = 'ACTIVE';
CREATE INDEX "dining_sessions_tableId_status_idx" ON "dining_sessions"("tableId", "status");
CREATE INDEX "dining_sessions_status_idx" ON "dining_sessions"("status");

-- Order Requests
CREATE TABLE "order_requests" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "requestNumber" TEXT NOT NULL UNIQUE,
    "status" "OrderRequestStatus" NOT NULL DEFAULT 'PENDING',
    "orderType" "OrderType" NOT NULL,
    "source" "OrderSource" NOT NULL DEFAULT 'PUBLIC',
    "customerSessionId" TEXT,
    "diningSessionId" TEXT,
    "customerName" TEXT NOT NULL,
    "customerPhone" TEXT,
    "customerNote" TEXT,
    "requestedTotal" INTEGER NOT NULL,
    "acceptedOrderId" TEXT UNIQUE,
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_requests_customerSessionId_fkey" FOREIGN KEY ("customerSessionId") REFERENCES "customer_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "order_requests_diningSessionId_fkey" FOREIGN KEY ("diningSessionId") REFERENCES "dining_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "order_requests_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_requests_status_createdAt_idx" ON "order_requests"("status", "createdAt");
CREATE INDEX "order_requests_customerSessionId_idx" ON "order_requests"("customerSessionId");
CREATE INDEX "order_requests_diningSessionId_idx" ON "order_requests"("diningSessionId");
CREATE INDEX "order_requests_requestNumber_idx" ON "order_requests"("requestNumber");

-- Order Request Items
CREATE TABLE "order_request_items" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "requestId" TEXT NOT NULL,
    "productId" TEXT,
    "productNameSnapshot" TEXT NOT NULL,
    "unitPriceSnapshot" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "note" TEXT,
    "lineSubtotal" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_request_items_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "order_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "order_request_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_request_items_requestId_idx" ON "order_request_items"("requestId");

-- Order Request Item Options
CREATE TABLE "order_request_item_options" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "requestItemId" TEXT NOT NULL,
    "productOptionId" TEXT,
    "optionGroupNameSnapshot" TEXT NOT NULL,
    "optionNameSnapshot" TEXT NOT NULL,
    "additionalPriceSnapshot" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_request_item_options_requestItemId_fkey" FOREIGN KEY ("requestItemId") REFERENCES "order_request_items"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "order_request_item_options_productOptionId_fkey" FOREIGN KEY ("productOptionId") REFERENCES "product_options"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_request_item_options_requestItemId_idx" ON "order_request_item_options"("requestItemId");

-- Orders
CREATE TABLE "orders" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "orderNumber" TEXT NOT NULL UNIQUE,
    "source" "OrderSource" NOT NULL DEFAULT 'STAFF',
    "orderType" "OrderType" NOT NULL,
    "status" "OrderStatus" NOT NULL DEFAULT 'OPEN',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'UNPAID',
    "fulfillmentStatus" "FulfillmentStatus" NOT NULL DEFAULT 'NOT_STARTED',
    "diningSessionId" TEXT,
    "customerSessionId" TEXT,
    "customerName" TEXT,
    "customerPhone" TEXT,
    "subtotalAmount" INTEGER NOT NULL,
    "discountAmount" INTEGER NOT NULL DEFAULT 0,
    "totalAmount" INTEGER NOT NULL,
    "paidAmount" INTEGER NOT NULL DEFAULT 0,
    "remainingAmount" INTEGER NOT NULL,
    "createdById" TEXT,
    "completedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "cancelledById" TEXT,
    "cancelReason" TEXT,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "orders_diningSessionId_fkey" FOREIGN KEY ("diningSessionId") REFERENCES "dining_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "orders_customerSessionId_fkey" FOREIGN KEY ("customerSessionId") REFERENCES "customer_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "orders_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "orders_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "orders_orderNumber_idx" ON "orders"("orderNumber");
CREATE INDEX "orders_status_createdAt_idx" ON "orders"("status", "createdAt");
CREATE INDEX "orders_diningSessionId_idx" ON "orders"("diningSessionId");
CREATE INDEX "orders_customerSessionId_idx" ON "orders"("customerSessionId");
CREATE INDEX "orders_paymentStatus_idx" ON "orders"("paymentStatus");
CREATE INDEX "orders_fulfillmentStatus_idx" ON "orders"("fulfillmentStatus");

-- Add FK from order_requests to orders
ALTER TABLE "order_requests" ADD CONSTRAINT "order_requests_acceptedOrderId_fkey" FOREIGN KEY ("acceptedOrderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Order Items
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "orderId" TEXT NOT NULL,
    "productId" TEXT,
    "productNameSnapshot" TEXT NOT NULL,
    "unitPriceSnapshot" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "lineSubtotal" INTEGER NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "order_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_items_orderId_idx" ON "order_items"("orderId");

-- Order Item Options
CREATE TABLE "order_item_options" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "orderItemId" TEXT NOT NULL,
    "productOptionId" TEXT,
    "optionGroupNameSnapshot" TEXT NOT NULL,
    "optionNameSnapshot" TEXT NOT NULL,
    "additionalPriceSnapshot" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_item_options_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES "order_items"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "order_item_options_productOptionId_fkey" FOREIGN KEY ("productOptionId") REFERENCES "product_options"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_item_options_orderItemId_idx" ON "order_item_options"("orderItemId");

-- Payments
CREATE TABLE "payments" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "orderId" TEXT NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentTransactionStatus" NOT NULL DEFAULT 'PENDING',
    "amount" INTEGER NOT NULL,
    "reference" TEXT NOT NULL UNIQUE,
    "provider" TEXT,
    "providerPaymentId" TEXT,
    "createdById" TEXT NOT NULL,
    "confirmedById" TEXT,
    "expiresAt" TIMESTAMP(3),
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "payments_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "payments_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "payments_confirmedById_fkey" FOREIGN KEY ("confirmedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "payments_orderId_idx" ON "payments"("orderId");
CREATE INDEX "payments_reference_idx" ON "payments"("reference");
CREATE INDEX "payments_status_idx" ON "payments"("status");

-- Payment Transactions
CREATE TABLE "payment_transactions" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "paymentId" TEXT,
    "provider" TEXT NOT NULL,
    "providerTransactionId" TEXT NOT NULL,
    "transactionReference" TEXT,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'VND',
    "direction" "TransactionDirection" NOT NULL DEFAULT 'INBOUND',
    "rawPayload" JSONB,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reconciliationStatus" TEXT NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "payment_transactions_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "payments"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE ("provider", "providerTransactionId")
);

CREATE INDEX "payment_transactions_paymentId_idx" ON "payment_transactions"("paymentId");
CREATE INDEX "payment_transactions_transactionReference_idx" ON "payment_transactions"("transactionReference");

-- Order Events
CREATE TABLE "order_events" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "orderId" TEXT NOT NULL,
    "actorType" "ActorType" NOT NULL,
    "actorId" TEXT,
    "eventType" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "order_events_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "order_events_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "order_events_orderId_createdAt_idx" ON "order_events"("orderId", "createdAt");
CREATE INDEX "order_events_eventType_idx" ON "order_events"("eventType");

-- Customer Notifications
CREATE TABLE "customer_notifications" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "customerSessionId" TEXT NOT NULL,
    "requestId" TEXT,
    "orderId" TEXT,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "customer_notifications_customerSessionId_fkey" FOREIGN KEY ("customerSessionId") REFERENCES "customer_sessions"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "customer_notifications_customerSessionId_createdAt_idx" ON "customer_notifications"("customerSessionId", "createdAt");
CREATE INDEX "customer_notifications_readAt_idx" ON "customer_notifications"("readAt");

-- Store Settings
CREATE TABLE "store_settings" (
    "id" TEXT NOT NULL PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    "key" TEXT NOT NULL UNIQUE,
    "value" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
