# Requirements Document

## Introduction

Nhiên POS là nền tảng point-of-sale và public-ordering tích hợp cho doanh nghiệp F&B Nhiên. Hệ thống hỗ trợ 3 kênh đặt hàng: Staff POS (nhân viên tạo đơn trực tiếp), Table QR Ordering (khách scan QR tại bàn), và Takeaway Ordering (khách đặt mang về qua public menu). Public requests không trở thành official orders cho đến khi staff duyệt — đây là quy tắc nghiệp vụ cốt lõi không được thay đổi.

Hệ thống được xây dựng trên một codebase Next.js duy nhất với PostgreSQL và Prisma, triển khai theo 8 phase từ foundation đến production readiness.

## Glossary

- **System**: Nhiên POS application (Next.js App Router)
- **Staff**: Nhân viên có tài khoản hệ thống với role STAFF hoặc ADMIN
- **Admin**: Nhân viên với role ADMIN, có toàn quyền cấu hình hệ thống
- **Guest**: Khách hàng không có tài khoản, truy cập qua public session
- **POS**: Point-of-sale interface dành cho Staff
- **Order**: Đơn hàng chính thức đã được tạo trong hệ thống
- **OrderRequest**: Yêu cầu đặt hàng từ Guest, chờ Staff duyệt mới thành Order
- **DiningSession**: Phiên phục vụ tại bàn, do Staff mở khi khách đến
- **CustomerSession**: Session ẩn danh của Guest, không yêu cầu đăng ký tài khoản
- **TableQrToken**: Token ngẫu nhiên được mã hoá trong QR, dùng để xác định bàn server-side
- **Snapshot**: Bản sao tên sản phẩm và giá tại thời điểm tạo order/request, không thay đổi sau đó
- **VietQR**: Phương thức thanh toán qua QR chuyển khoản ngân hàng Việt Nam
- **FulfillmentStatus**: Trạng thái chuẩn bị và bàn giao món, độc lập với OrderStatus và PaymentStatus
- **Prisma**: ORM dùng để tương tác với PostgreSQL
- **Zod**: Thư viện validation schema cho TypeScript
- **Zustand**: Client state management library
- **TanStack_Query**: Server state management library (data fetching, caching)

---

## Requirements

### Requirement 1: Foundation và Project Setup

**User Story:** As a developer, I want a fully configured Next.js project foundation, so that the team can build features on a stable, type-safe, and testable base.

#### Acceptance Criteria

1. THE System SHALL be implemented as a single Next.js App Router application with TypeScript strict mode enabled.
2. THE System SHALL use PostgreSQL as the database and Prisma as the ORM with migration-based schema management.
3. WHEN the application starts, THE System SHALL validate all required environment variables and refuse to start if any required variable is absent or empty, displaying an error message indicating which variable is missing.
4. THE System SHALL organize source code into route groups `(auth)`, `(staff)`, `(admin)`, and `(public)` with separate layouts and authorization policies for each group.
5. THE System SHALL provide API namespaces `/api/public/v1`, `/api/staff/v1`, `/api/admin/v1`, `/api/webhooks`, and `/api/health` such that a request authenticated for one namespace is rejected with an authorization error when it targets any other namespace.
6. THE System SHALL apply Tailwind CSS for styling and initialize shadcn/ui as the component library without adding Ant Design or MUI.
7. THE System SHALL include `lint`, `typecheck`, and `test` commands, each of which exits with code 0 when all checks pass and exits with a non-zero code when any check fails.
8. THE System SHALL define design tokens for colors, spacing, and typography in the Tailwind configuration using the palette: Cream `#F8F5EF`, Terracotta `#B65C3A`, Brown `#453B32`, and Olive `#82916A`, such that any component referencing these tokens renders the correct hex value.

---

### Requirement 2: Authentication và Authorization

**User Story:** As a staff member, I want to log in securely and have my permissions enforced on every action, so that unauthorized operations are impossible regardless of client-side state.

#### Acceptance Criteria

1. THE System SHALL authenticate Staff and Admin users with secure server-side sessions using HttpOnly, Secure (in production), and SameSite=Lax cookies.
2. THE System SHALL hash passwords using a modern password hashing algorithm and never store or expose raw passwords.
3. THE System SHALL enforce rate limiting on login attempts, allowing no more than 5 failed attempts per account within any 15-minute window.
4. THE System SHALL check permissions server-side on every protected API endpoint; hiding UI controls is not sufficient authorization.
5. WHEN an Admin disables a staff account, THE System SHALL immediately invalidate all active sessions belonging to that account.
6. THE System SHALL recognize two staff roles: ADMIN (full access) and STAFF (operational access without product, staff, or payment-provider configuration by default).
7. IF a request arrives at a Staff or Admin endpoint without a valid authenticated session, THEN THE System SHALL return HTTP 401 and reject the request.
8. IF a Staff user attempts an operation that requires ADMIN or a specific permission they do not hold, THEN THE System SHALL return HTTP 403 and reject the request.
9. IF a login attempt is made after the rate limit for that account is exceeded, THEN THE System SHALL reject the attempt and return an error indicating the account is temporarily locked, without revealing whether the account exists.
10. THE System SHALL never expose database credentials, auth secrets, or provider secrets to the browser or through `NEXT_PUBLIC_*` environment variables.

---

### Requirement 3: Catalog Management (Categories và Products)

**User Story:** As an Admin, I want to manage categories, products, and option groups, so that the menu is always accurate and staff and guests see the correct offerings and prices.

#### Acceptance Criteria

1. THE Admin SHALL create, edit, and archive categories with fields: name, slug (unique across all categories, URL-safe alphanumeric and hyphens only, 1–100 characters), description, image URL, sort order, and active status.
2. THE Admin SHALL create, edit, and archive products with fields: name, slug (unique across all products, URL-safe alphanumeric and hyphens only, 1–100 characters), description, image URL, price (integer VND, minimum 0), optional cost price (integer VND, minimum 0), category, sort order, active status, and availability status (one of: available, unavailable).
3. THE Admin SHALL configure ProductOptionGroups per product with fields: name, selection type (SINGLE or MULTIPLE), required flag, min selections (integer ≥ 0), max selections (integer ≥ 1), and sort order, where min selections must not exceed max selections, and a required group must have min selections ≥ 1.
4. THE Admin SHALL configure ProductOptions per group with fields: name, additional price (integer VND, minimum 0), active status, and sort order.
5. THE System SHALL store all monetary amounts as integer VND and never use floating-point arithmetic for money calculations.
6. IF an Admin attempts to delete a product or category that is referenced by historical orders or requests, THEN THE System SHALL archive the record instead of hard-deleting it; IF an Admin attempts to archive a category that contains at least one active product, THEN THE System SHALL reject the action and display an error indicating that all products in the category must be archived or reassigned first.
7. WHEN a product's availability status is set to unavailable, THE System SHALL prevent that product from being added to new orders or requests while preserving existing order history.
8. THE System SHALL provide search by name and filter by category, active status, and availability status in the product management UI, returning all matching products within 2 seconds for a catalog of up to 10,000 products.

---

### Requirement 4: Staff POS – Order Creation

**User Story:** As a Staff member, I want to create orders quickly from the POS interface on mobile and tablet, so that I can serve customers efficiently with accurate server-calculated prices.

#### Acceptance Criteria

1. WHEN a Staff member submits a new order through the POS, THE System SHALL validate product and option availability, calculate all prices server-side, snapshot product names and prices, generate a unique order number, and create the Order and all items in a single atomic operation.
2. IF any product or option in the submitted order is inactive or unavailable at time of submission, THEN THE System SHALL reject the create request with an error identifying which items are unavailable and persist no partial order record.
3. THE System SHALL initialize every newly created Order with status OPEN and payment status UNPAID.
4. THE System SHALL support two order types at creation time: DINE_IN and TAKEAWAY.
5. WHILE viewport width is less than 768px, THE POS SHALL display products in a 2-column grid with horizontal category scrolling and a cart summary that remains visible when the page is scrolled.
6. WHILE viewport width is between 768px and 1199px, THE POS SHALL display products in a 3–4 column grid with a persistent right-panel cart.
7. WHILE viewport width is 1200px or greater, THE POS SHALL display products in a sidebar layout with product grid and cart side by side.
8. WHEN a product with option groups is selected, THE System SHALL require the Staff member to complete all required option selections before adding the item to the cart.
9. THE System SHALL generate and store the order number uniquely; two simultaneous order creation requests must not produce duplicate order numbers.
10. THE System SHALL record an ORDER_CREATED audit event with actor type STAFF, actor ID, and timestamp for every new order.
11. IF the submitted order does not include all required option selections, THEN THE System SHALL reject the creation request with an error indicating which option groups are missing.

---

### Requirement 5: Staff POS – Order Editing

**User Story:** As a Staff member, I want to add, edit, and remove items from an open order, so that I can accommodate changes without creating a new order.

#### Acceptance Criteria

1. WHILE an Order has status OPEN, THE System SHALL allow Staff to add new items, recording the catalog unit price at the moment of addition as an immutable price snapshot for that line item.
2. WHEN new items are added to an existing Order, THE System SHALL keep the same Order ID and Order Number and leave existing item price snapshots unchanged.
3. WHILE an Order has status OPEN, THE System SHALL allow Staff to edit item quantity (minimum 1) and notes (maximum 500 characters) and to remove items, recalculating the Order total after each change.
4. IF an Order has status COMPLETED or CANCELLED, THEN THE System SHALL reject item add, edit, or remove requests through the normal staff flow.
5. WHEN a Staff member submits a modification to an Order whose version field does not match the version last loaded by that Staff member, THE System SHALL reject the modification with a conflict error indicating the Order was concurrently modified and leave the Order unchanged.
6. WHEN a pending VietQR payment attempt exists and the Order's net total changes due to item edits, THE System SHALL mark the existing attempt SUPERSEDED and preserve its reference and metadata for reconciliation.
7. THE System SHALL record ORDER_ITEM_ADDED, ORDER_ITEM_UPDATED, or ORDER_ITEM_REMOVED audit events for every item change, capturing the authenticated Staff member's identifier and the timestamp of the change.

---

### Requirement 6: Order Lifecycle – Completion và Cancellation

**User Story:** As a Staff member, I want to complete or cancel orders with confirmation and audit trails, so that order state accurately reflects operations and no financial data is lost.

#### Acceptance Criteria

1. WHEN a Staff member completes an OPEN Order, THE System SHALL set Order status to COMPLETED, record `completedAt` with the current timestamp, and append an ORDER_COMPLETED audit event containing the actor and timestamp.
2. WHEN a Staff member cancels an OPEN Order, THE System SHALL require explicit confirmation before proceeding, then require a cancellation reason between 1 and 255 characters, set Order status to CANCELLED, record the actor, timestamp, and reason, and append an ORDER_CANCELLED audit event.
3. IF a cancelled Order has one or more associated payments with a successful payment status, THEN THE System SHALL preserve all those payment records unmodified and display a notification indicating the number of outstanding payments that require manual refund or reconciliation action.
4. IF a Staff member attempts to complete or cancel an Order whose status is not OPEN, THEN THE System SHALL reject the action and display an error indicating that the Order's current status does not allow that transition.
5. THE System SHALL never hard-delete Orders, OrderItems, Payments, or OrderEvents.
6. THE System SHALL keep Order status, payment status, and fulfillment status as independent fields, such that updating one of these fields does not modify either of the other two.

---

### Requirement 7: Fulfillment Status Tracking

**User Story:** As a Staff member, I want to track the preparation and handover status of each order independently from payment, so that kitchen and service staff know what to prepare and deliver.

#### Acceptance Criteria

1. THE System SHALL track fulfillment status as one of: NOT_STARTED, PREPARING, READY, HANDED_OVER.
2. WHEN a Staff member updates the fulfillment status of an Order, THE System SHALL validate that the transition follows the allowed sequence (NOT_STARTED → PREPARING → READY → HANDED_OVER), persist the new status, and record a FULFILLMENT_STATUS_CHANGED audit event.
3. IF a Staff member requests a fulfillment status transition that does not follow the allowed sequence, THEN THE System SHALL reject the update and return an error indicating the transition is invalid, leaving the fulfillment status unchanged.
4. IF fulfillment status is READY or HANDED_OVER, THEN THE System SHALL NOT automatically change the order status to COMPLETED or the payment status to PAID.

---

### Requirement 8: Cash Payment Workflow

**User Story:** As a Staff member, I want to record cash payments accurately with idempotency, so that balances are correct and duplicate submissions cannot double-count revenue.

#### Acceptance Criteria

1. WHEN a Staff member submits a cash payment for an Order, THE System SHALL validate server-side that the payment amount is greater than 0 and does not exceed the Order's total amount, then record the payment in a transaction that atomically updates the Order's paid amount and remaining amount.
2. IF the submitted payment amount is less than or equal to 0, exceeds the Order's total amount, or cannot be parsed as a valid currency value, THEN THE System SHALL reject the request and return an error indicating the invalid amount without modifying any Order or payment record.
3. WHEN cash received exceeds the outstanding amount, THE System SHALL record only the amount applied to the Order balance and retain the received amount and computed change amount for cash reconciliation without marking the Order OVERPAID solely because a larger banknote was tendered.
4. THE System SHALL calculate all payment balances server-side; IF a request attempts to set payment status directly via a client-supplied value, THEN THE System SHALL reject the request and return an error indicating unauthorized status assignment without modifying any Order or payment record.
5. WHEN a Staff member submits a cash payment whose idempotency key matches a payment already recorded for that Order within the same session, THE System SHALL return the original payment result without creating a duplicate payment record or modifying the Order balance a second time.
6. IF a submitted idempotency key does not match any existing payment for that Order, THE System SHALL treat the submission as a new payment and proceed with validation and recording.
7. THE System SHALL record PAYMENT_CREATED and PAYMENT_SUCCEEDED audit events with actor, amount, and timestamp for every successful cash payment.
8. IF a cash payment fails validation or cannot be recorded, THE System SHALL record a PAYMENT_FAILED audit event with actor, attempted amount, failure reason, and timestamp.
9. WHEN a cash payment is successfully recorded, THE System SHALL update the Order's payment status to UNPAID, PARTIALLY_PAID, or PAID based solely on the server-calculated ratio of total paid amount to Order total amount.

---

### Requirement 9: VietQR Payment Workflow

**User Story:** As a Staff member, I want to generate a VietQR payment request and have transactions reconciled securely, so that bank transfers are recorded accurately without relying on unverified guest screenshots.

#### Acceptance Criteria

1. WHEN a Staff member initiates a VietQR payment for an Order, THE System SHALL calculate the current outstanding balance, create a Payment attempt record with a unique reference code, and generate a QR image using the configured payment provider.
2. THE System SHALL treat QR generation as a pending payment request only; creating a QR must NOT set the Order payment status to PAID or PARTIALLY_PAID.
3. WHEN a provider webhook arrives with a valid signature and conforming payload, THE System SHALL check the provider transaction ID for a prior record, and if none exists, match the reference code to the originating Order, compare the transaction amount to the Order's outstanding balance, and update the Order payment status and balance in a single operation.
4. IF an identical provider transaction ID has already been recorded, THEN THE System SHALL return a success response without creating a duplicate Payment record.
5. IF a provider webhook fails signature verification or contains a non-conforming payload, THEN THE System SHALL reject the request with an error response indicating the reason and make no change to any Order or Payment record.
6. WHEN a provider webhook transaction amount is greater than zero and less than the Order's outstanding balance, THE System SHALL record the payment and set the Order payment status to PARTIALLY_PAID, reducing the outstanding balance by the transaction amount.
7. WHEN a provider webhook arrives for a Payment attempt reference that has been superseded by a newer Payment attempt on the same Order, THE System SHALL still record the transaction and apply it against that Order's outstanding balance.
8. WHEN a payment amount exceeds the Order's outstanding balance, THE System SHALL set the Order status to OVERPAID, prevent the Order from being automatically closed, and require a Staff member with manager-level access to review and resolve the discrepancy before the Order can be closed.
9. THE System SHALL NOT expose an Order payment status of VERIFIED or display confirmed bank transfer status to any user until a live payment provider is configured, webhook signature verification is active, and at least one end-to-end transaction has been successfully processed in the production environment.

---

### Requirement 10: Table Management

**User Story:** As a Staff member with table-operation permission, I want to manage tables and their QR tokens, so that guests can scan to access the correct active session.

#### Acceptance Criteria

1. WHEN an Admin submits a create-table request with a unique code (1–20 characters), name (1–100 characters), optional capacity (1–999), and active status, THE System SHALL persist the table record and return the created table data.
2. IF the submitted table code already exists, THEN THE System SHALL reject the request with an error indicating the code is already in use, and no table record SHALL be created.
3. WHEN a table is created, THE System SHALL generate a QR token of at least 128 bits of cryptographic randomness, store only its hash server-side, and associate the token with that table, without exposing internal table IDs in the token.
4. WHEN a QR token is revoked or regenerated by an Admin, THE System SHALL invalidate the old token within 1 second, preventing any new session resolution against it, and generate a replacement token if regeneration was requested.
5. THE System SHALL record a TABLE_QR_REVOKED audit event when a token is revoked, and a TABLE_QR_GENERATED audit event when a token is first generated or regenerated.

---

### Requirement 11: DiningSession Management

**User Story:** As a Staff member, I want to open and close table dining sessions, so that only the correct guests can submit requests at an active table and sessions are cleanly closed when guests leave.

#### Acceptance Criteria

1. WHEN a Staff member opens a DiningSession for a table, THE System SHALL create the session, store `openedById` and `openedAt`, and mark the table status as OCCUPIED.
2. IF an ACTIVE DiningSession already exists for a table when a Staff member attempts to open a new DiningSession, THEN THE System SHALL reject the request and return an error indicating the table already has an active session, leaving the existing session and table status unchanged.
3. THE System SHALL enforce the constraint that at most one DiningSession with status ACTIVE exists per table at any point in time.
4. WHEN a Staff member initiates closing a DiningSession, THE System SHALL check for OrderRequests with status PENDING and Orders with status OPEN associated with that session, and display a warning listing the count of each unresolved item if any exist.
5. WHEN a Staff member confirms closing a DiningSession, THE System SHALL set the session status to CLOSED, record `closedAt` and `closedById`, and mark the table status as AVAILABLE.
6. IF a submitted OrderRequest is associated with a table whose DiningSession status is not ACTIVE, THEN THE System SHALL reject the request with an error indicating no active session exists for that table.
7. WHEN a DiningSession is opened or closed, THE System SHALL record a DINING_SESSION_OPENED or DINING_SESSION_CLOSED audit event respectively, capturing the actor identifier and timestamp.

---

### Requirement 12: Public Guest Session

**User Story:** As a Guest, I want to browse the menu and submit orders without creating an account, so that the experience is frictionless and my data remains private.

#### Acceptance Criteria

1. WHEN a Guest accesses the public menu for the first time without an existing CustomerSession cookie, THE System SHALL create a CustomerSession with a random token of at least 128 bits of entropy, storing only the token's hash server-side.
2. WHEN a CustomerSession is created, THE System SHALL issue the session token as an HttpOnly, Secure (in production), SameSite=Strict cookie and SHALL NOT include the token in URL query strings or response bodies.
3. THE System SHALL bind all OrderRequest and Order read access to the CustomerSession token present in the request cookie; a request referencing an OrderRequest or Order that belongs to a different CustomerSession SHALL be rejected.
4. IF a request attempts to read an OrderRequest or Order belonging to a different CustomerSession, THEN THE System SHALL return an error response indicating the resource was not found, without disclosing that the resource exists.
5. THE System SHALL NOT model the Guest as a staff UserRole; THE System SHALL represent guest-originated orders using Order.source = PUBLIC and a CustomerSession identity.
6. IF a request includes a CustomerSession cookie referencing a valid, non-expired session, THEN THE System SHALL restore that CustomerSession and associate subsequent requests with it.
7. IF a request includes a CustomerSession cookie referencing a session that does not exist or has expired, THEN THE System SHALL create a new CustomerSession and issue a replacement cookie, discarding the invalid token.
8. THE System SHALL expire a CustomerSession that has received no request activity for 24 hours, after which the stored token hash SHALL be deleted.

---

### Requirement 13: Table QR Ordering – Guest Request Submission

**User Story:** As a Guest at a table, I want to scan the table QR code and submit a food order, so that my request reaches the staff for approval without creating an account.

#### Acceptance Criteria

1. WHEN a Guest scans a QR code, THE System SHALL resolve the token server-side to identify the associated table.
2. IF the QR token is invalid or revoked, THEN THE System SHALL reject access and return an error indicating the token is not valid.
3. WHEN a valid QR token resolves to a table, THE System SHALL check whether an ACTIVE DiningSession exists for that table.
4. IF no ACTIVE DiningSession exists for the resolved table, THEN THE System SHALL reject the request and return an error indicating the table is not currently accepting orders.
5. WHEN a Guest submits an OrderRequest for a DINE_IN table, THE System SHALL calculate and store a price snapshot server-side for all submitted items and options at the moment of submission.
6. WHEN a Guest submits an OrderRequest for a DINE_IN table, THE System SHALL create the OrderRequest with status PENDING and return a tracking token, valid for 24 hours, that the Guest can use to check the request status.
7. IF an OrderRequest contains an item that does not exist in the menu or is not currently available, THEN THE System SHALL reject the entire request and return an error identifying which items are invalid.
8. THE System SHALL require that every submitted OrderRequest contains at least one item that exists in the menu and is marked as available.
9. THE System SHALL reject OrderRequest submissions from a single QR token that exceed 10 requests within any 60-second window, returning an error indicating the rate limit has been reached.
10. THE System SHALL NOT trust a client-supplied tableId as proof of table access; all table resolution must go through the QR token.

---

### Requirement 14: Takeaway Ordering – Guest Request Submission

**User Story:** As a Guest ordering takeaway, I want to submit a request with my name, so that staff can prepare my order and I can pick it up.

#### Acceptance Criteria

1. WHEN a Guest submits a takeaway OrderRequest, THE System SHALL require a customer name between 1 and 100 characters in length.
2. IF a Guest submits a takeaway OrderRequest without a customer name, THEN THE System SHALL reject the request with a validation error indicating the name is required.
3. THE System SHALL accept an optional customer phone number for takeaway requests and must not require it.
4. WHEN a Guest submits a takeaway OrderRequest, THE System SHALL calculate and store a price snapshot based on current menu item prices at submission time, then create the OrderRequest with status PENDING.
5. WHEN a Guest submits a takeaway OrderRequest, THE System SHALL return a tracking token that is unique per request and not guessable from sequential enumeration.
6. THE System SHALL accept an optional pickup time and an optional customer note of at most 500 characters in takeaway requests.
7. WHILE a takeaway OrderRequest is PENDING, WHEN the owning Guest submits a cancellation request with the matching tracking token, THE System SHALL update the OrderRequest status to CANCELLED.
8. IF a Guest submits a cancellation request with an absent or non-matching tracking token, THEN THE System SHALL reject the cancellation with an error indicating the token is invalid.

---

### Requirement 15: Request Price Snapshot Policy

**User Story:** As a business owner, I want submitted request prices to be frozen at submission time, so that price changes after submission do not silently alter what guests agreed to pay.

#### Acceptance Criteria

1. WHEN a Guest submits an OrderRequest, THE System SHALL calculate and persist, server-side, a price snapshot for each line item containing the item price, each selected option price, and the requested quantity at submission time; this snapshot is calculated by the server, not supplied by the client.
2. WHILE an OrderRequest has status PENDING, THE System SHALL preserve the original price snapshot even if the catalog price of a product changes.
3. WHEN a Staff member approves a PENDING OrderRequest, THE System SHALL use the preserved snapshot prices when creating or updating the Order, not the current catalog prices.
4. IF one or more products or options in a PENDING OrderRequest become unavailable, THEN THE System SHALL require the Staff member to reject the entire OrderRequest with a reason of at least 1 character and no more than 500 characters, rather than partially modifying or silently removing the affected lines.

---

### Requirement 16: Staff Request Inbox and Approval Workflow

**User Story:** As a Staff member, I want to review, accept, or reject incoming public requests from an inbox, so that only valid requests become official orders.

#### Acceptance Criteria

1. THE System SHALL provide a Staff Request Inbox with a Pending tab (requests awaiting action) and a Processed tab (accepted, rejected, or cancelled requests).
2. WHEN the Staff Request Inbox is opened, THE System SHALL display each request card with: request number, source (TABLE QR or TAKEAWAY), table code if DINE_IN, customer name and optional phone, items with options and quantities, submitted price snapshot, and creation time.
3. WHEN a Staff member accepts a PENDING OrderRequest, THE System SHALL begin a database transaction, lock the request row, verify the request is still PENDING, verify each requested product and option has status AVAILABLE, preserve the server-created price snapshot, and for DINE_IN verify the DiningSession remains ACTIVE.
4. IF all acceptance preconditions pass, THEN THE System SHALL find the eligible OPEN Order for the DiningSession or create a new one, append approved items, recalculate totals, set `acceptedOrderId`, `reviewedById`, `reviewedAt`, and status ACCEPTED, record audit events, create a CustomerNotification, and commit the transaction atomically.
5. IF any acceptance precondition fails (request no longer PENDING, a product or option is unavailable, or the DiningSession is not ACTIVE), THEN THE System SHALL abort the transaction, return an error indicating the specific failed precondition, and leave the OrderRequest status unchanged.
6. IF two simultaneous approval requests arrive for the same OrderRequest, THEN THE System SHALL allow only one to succeed using row locking or compare-and-swap, and the second SHALL receive a conflict response without creating duplicate Order items.
7. WHEN a Staff member rejects a PENDING OrderRequest, THE System SHALL require a rejection reason of at least 1 character and no more than 500 characters, store `reviewedById`, `reviewedAt`, and `rejectionReason`, set status to REJECTED, create a CustomerNotification, and preserve the request for history.
8. IF a Staff member submits a rejection with an empty or whitespace-only rejection reason, THEN THE System SHALL reject the submission and display a validation error indicating the reason is required.
9. THE System SHALL NOT create an Order when a request is rejected.
10. THE System SHALL NOT automatically expire PENDING requests; staff must process them manually.
11. WHILE the Staff Request Inbox Pending tab is open, THE System SHALL display elapsed waiting time for each pending request and apply visual highlighting to any request that has been waiting 10 minutes or longer.

---

### Requirement 17: Shared Table Order – Multi-Guest Behavior

**User Story:** As a business owner, I want all guests at the same table to share a single order bill, so that the table is managed as one unit rather than per-guest bills.

#### Acceptance Criteria

1. WHEN a Staff member approves a DINE_IN OrderRequest, THE System SHALL find the existing Order whose status is OPEN and whose DiningSession matches the approved request's DiningSession, and append the approved items to that Order.
2. IF no Order with status OPEN exists for the active DiningSession at the time a DINE_IN OrderRequest is approved, THEN THE System SHALL create a new Order within that DiningSession and add the approved items to it.
3. THE System SHALL NOT create more than one Order with status OPEN per DiningSession at any time; IF an action would result in a second OPEN Order for the same DiningSession, THEN THE System SHALL reject the action and return an error indicating a conflicting open order exists.
4. WHEN the current table Order has been fully PAID and COMPLETED, THE System SHALL NOT reopen or mutate that Order even if a new OrderRequest is approved for the same DiningSession.
5. WHEN a new OrderRequest is approved after the previous table Order reaches COMPLETED status, THE System SHALL create a new Order with a distinct Order Number within the same DiningSession.

---

### Requirement 18: Guest Order and Request Tracking

**User Story:** As a Guest, I want to track the status of my submitted request and the resulting order, so that I know when my order is accepted, being prepared, and ready.

#### Acceptance Criteria

1. WHEN a Guest accesses the tracking URL received at OrderRequest submission, THE System SHALL display: request number, current status, item list, submitted price snapshot, and submission time.
2. WHILE an OrderRequest has status PENDING, THE System SHALL display a cancellation action on the tracking page for the owning Guest; WHEN the Guest activates that cancellation action, THE System SHALL transition the OrderRequest status to CANCELLED and update the displayed status immediately.
3. IF an OrderRequest has status ACCEPTED, THEN THE System SHALL display the official Order number, fulfillment status (one of: PREPARING, READY, SERVED), and payment status (one of: UNPAID, PAID) to the owning Guest.
4. THE System SHALL NOT expose staff-only notes, internal audit data, Order IDs for other customers, or any other guest's information on the public tracking page.
5. THE Guest tracking page SHALL poll the server every 5–10 seconds to reflect current status without requiring a page reload; IF a poll request fails, THEN THE System SHALL retain the last successfully retrieved status on screen and display an indicator that the status may be out of date.
6. IF a Guest accesses a tracking URL that does not correspond to an existing OrderRequest or corresponds to an OrderRequest owned by a different Guest, THEN THE System SHALL display an error indicating the request was not found and SHALL NOT reveal whether the OrderRequest exists.

---

### Requirement 19: CustomerNotification

**User Story:** As a Guest, I want to receive notifications when my request status changes, so that I do not need to manually refresh to find out if my order was accepted or rejected.

#### Acceptance Criteria

1. WHEN an OrderRequest transitions to ACCEPTED, THE System SHALL create a CustomerNotification of type ORDER_ACCEPTED linked to the owning CustomerSession, with a title referencing the request number and a message stating the order has been confirmed.
2. WHEN an OrderRequest transitions to REJECTED, THE System SHALL create a CustomerNotification of type ORDER_REJECTED linked to the owning CustomerSession, with a title referencing the request number and a message including the rejection reason provided by the Staff member.
3. WHEN a Guest requests their notifications using their CustomerSession token, THE System SHALL return for each notification: notification ID, type, title, message, read status, and creation timestamp.
4. IF a notification request is made with an absent or invalid CustomerSession token, THEN THE System SHALL return an authentication error without exposing any notification data.
5. WHEN a Guest marks a notification as read, THE System SHALL record `readAt` and not deliver the same notification as unread again.
6. IF a Guest submits a mark-as-read request for a notification that already has `readAt` set, THEN THE System SHALL return a success response without modifying the existing `readAt` timestamp.
7. THE System SHALL NOT expose another Guest's notifications through the public API.

---

### Requirement 20: Staff Request Inbox – Realtime Awareness

**User Story:** As a Staff member, I want the Request Inbox to alert me to new pending requests promptly, so that I can process them before guests wait too long.

#### Acceptance Criteria

1. THE Staff Request Inbox SHALL poll for new pending requests at an interval of 5–10 seconds and update both the pending count and the full pending request list in the UI without requiring a manual page reload.
2. WHEN a new OrderRequest arrives while the Staff member is viewing the inbox, THE System SHALL update the inbox display within one polling cycle (at most 10 seconds).
3. WHERE a browser notification permission is granted by the Staff member, THE System SHALL play an optional sound or display a browser notification once per newly arriving OrderRequest.
4. THE System SHALL display elapsed waiting time for each pending request, calculated from the OrderRequest creation timestamp, and update the displayed duration each polling cycle.
5. THE System SHALL sort pending requests by oldest first by default and allow the Staff member to switch to newest-first sort order.

---

### Requirement 21: Admin Dashboard and Reporting

**User Story:** As an Admin, I want a dashboard and reports showing revenue, order counts, and product performance, so that I can make informed business decisions.

#### Acceptance Criteria

1. WHEN an Admin views the dashboard, THE Admin dashboard SHALL display the following metrics for the current calendar day by default, with the ability to select a custom date range: gross order value, collected revenue, outstanding balance, order count, average order value, open/unpaid order count, revenue by source (STAFF and PUBLIC), revenue by order type (DINE_IN and TAKEAWAY), payment method split, best-selling products (top 10 by quantity sold), pending public request count, and request acceptance and rejection counts.
2. THE System SHALL NOT count PENDING or REJECTED OrderRequests as revenue in any dashboard metric.
3. THE System SHALL NOT count unpaid order value as collected revenue; unpaid order value SHALL be reflected only in the outstanding balance metric.
4. THE System SHALL exclude cancelled orders from gross order value, collected revenue, order count, average order value, revenue by source, revenue by order type, payment method split, and best-selling product metrics, while preserving their audit and payment history.
5. WHEN an Admin or permitted Staff member requests a report, THE Reports section SHALL provide revenue breakdown by calendar day, calendar week (Monday–Sunday), and calendar month with order count, average order value, top 10 products by quantity sold, revenue by category, revenue by payment method, revenue by source, and revenue by order type for the selected period.
6. THE System SHALL make financial report data available only to Admin users and Staff users with an active reporting permission flag on their account.
7. IF a user without Admin role or active reporting permission attempts to access financial report data, THEN THE System SHALL deny access and return an error indicating insufficient permissions without exposing any report data.

---

### Requirement 22: Staff Management

**User Story:** As an Admin, I want to create and manage staff accounts securely, so that only active, authorized staff can access the system.

#### Acceptance Criteria

1. WHEN the Admin submits a new staff account form, THE System SHALL create the account with the provided name (1–100 characters), unique username or email, role (ADMIN or STAFF), and an active status defaulting to active.
2. IF the submitted username or email already exists, THEN THE System SHALL reject the creation request with an error indicating a duplicate identifier, leaving no account created.
3. WHEN the Admin activates or deactivates a staff account, THE System SHALL update that account's active status immediately; a deactivated account must be denied login from that point onward.
4. WHEN the Admin initiates a credential reset for a staff account, THE System SHALL generate a time-limited reset token (valid for no more than 24 hours) and deliver it to the account's registered email, without returning or displaying the current or new password hash at any point.
5. WHEN a staff account completes a successful login, THE System SHALL record the timestamp of that login as `lastLoginAt` on the account.
6. THE System SHALL NOT include password hashes in any API response payload for staff account data.

---

### Requirement 23: Store Settings

**User Story:** As an Admin, I want to configure store information and payment settings, so that the system reflects the correct business details and payment instructions.

#### Acceptance Criteria

1. WHEN the Admin submits store settings, THE System SHALL validate and persist the following fields: store name (1–100 characters), address (1–255 characters), phone (valid Vietnamese format, 10–11 digits), logo (JPEG or PNG, maximum 2 MB), currency fixed to VND, receiving bank account details, VietQR provider configuration, and order numbering settings.
2. IF any submitted store settings field fails validation, THEN THE System SHALL reject the entire submission, preserve the previously saved settings unchanged, and return an error indicating which fields are invalid.
3. THE System SHALL NOT return payment provider secrets, bank account credentials, VietQR signing keys, or authentication secrets (API keys, signing secrets, access tokens) through any public or client-facing API response.
4. THE System SHALL store payment provider secrets in server-only environment variables, never in `NEXT_PUBLIC_*` variables or persisted to any data store in a form retrievable by the browser.
5. WHEN the Admin submits valid store settings, THE System SHALL confirm successful save with a success notification within 3 seconds of submission.
6. WHEN the Admin configures order numbering settings, THE System SHALL validate that the prefix is 1–10 alphanumeric characters and the starting sequence number is between 1 and 999999.

---

### Requirement 24: Responsive Design and Accessibility

**User Story:** As a user on any device, I want the application to be usable and accessible on mobile, tablet, and desktop, so that staff and guests can operate it comfortably.

#### Acceptance Criteria

1. THE System SHALL render all public-facing pages without horizontal overflow at a 360px viewport width.
2. THE Staff POS SHALL use a 2-column product grid on mobile (< 768px), a 3–4 column grid on tablet (768px – 1199px), and a sidebar layout on desktop (>= 1200px).
3. THE System SHALL provide touch targets of at least 44px on interactive controls in mobile and tablet layouts.
4. WHILE a network request is in-flight for a form submission or data-fetch operation, THE System SHALL display a loading indicator and disable the triggering control until the response is received.
5. IF a form submission or destructive action request completes, THEN THE System SHALL display a success or error state indicating the outcome before returning the control to an enabled state.
6. THE System SHALL require confirmation via a modal dialog requiring explicit user acknowledgment before executing destructive actions such as order cancellation, session closure, and product archival.
7. WHILE the mobile soft keyboard is open, THE System SHALL keep the primary action control of the active form visible within the viewport without requiring the user to scroll horizontally.
8. THE System SHALL render the public menu and checkout flows without horizontal overflow or overlapping interactive controls at a 360px viewport width on both WebKit-based and Chromium-based mobile browsers.

---

### Requirement 25: Audit and Data Integrity

**User Story:** As an Admin, I want all significant system events to be logged in an append-only audit trail, so that operations can be investigated and financial data cannot be silently altered.

#### Acceptance Criteria

1. THE System SHALL record append-only OrderEvent records for each of the following transitions: ORDER_CREATED, ORDER_ITEM_ADDED, ORDER_ITEM_UPDATED, ORDER_ITEM_REMOVED, ORDER_CANCELLED, ORDER_COMPLETED, REQUEST_CREATED, REQUEST_ACCEPTED, REQUEST_REJECTED, REQUEST_CANCELLED, PAYMENT_CREATED, PAYMENT_SUCCEEDED, PAYMENT_FAILED, PAYMENT_SUPERSEDED, PAYMENT_RECONCILED, DINING_SESSION_OPENED, DINING_SESSION_CLOSED, TABLE_QR_REVOKED, FULFILLMENT_STATUS_CHANGED.
2. EACH audit event SHALL record: actor type (STAFF, CUSTOMER, SYSTEM, or PROVIDER), actor ID or session ID, entity type and ID, event type, timestamp (UTC), and a metadata payload capturing the before-state and after-state values of fields changed by the triggering operation.
3. THE System SHALL NOT hard-delete Orders, OrderItems, OrderRequests, Payments, PaymentTransactions, or OrderEvents through any application code path; schema migrations and direct database administration operations are outside this constraint.
4. THE System SHALL execute all multi-record business operations — including request approval, order creation, item addition, payment recording, and session state changes — within a single database transaction, and IF the transaction fails, THEN THE System SHALL roll back all writes in that transaction and return an error to the caller without partially persisting any record.
5. THE System SHALL enforce non-negative integer VND amounts on all monetary fields using database constraints.
6. THE System SHALL enforce positive item quantities using a database constraint.
7. THE System SHALL enforce at least one item in every submitted OrderRequest and created Order at the application layer, rejecting the operation with an error indicating insufficient items if the item count is zero.
8. THE System SHALL enforce immutability of OrderEvent records by prohibiting updates and deletes on the OrderEvents table through database constraints.

---

### Requirement 26: Error Handling và User-Facing Messages

**User Story:** As a user, I want clear Vietnamese error messages when something goes wrong, so that I understand what happened and what to do next without seeing technical stack traces.

#### Acceptance Criteria

1. THE System SHALL return structured error responses with correct HTTP status codes for all expected error conditions: validation error (400), unauthenticated (401), unauthorized (403), not found (404), conflict (409), rate limit exceeded (429), and server error (500).
2. THE System SHALL display user-facing error messages in Vietnamese for all public and staff-facing screens, where each message identifies what went wrong and states the action the user should take next.
3. THE System SHALL NOT expose stack traces, database error details, secrets, or internal service names in API responses returned to clients.
4. THE System SHALL include a unique request correlation ID in every error response so that users can reference it when reporting issues to support staff.
5. WHEN an Order has a concurrent update conflict, THE System SHALL return HTTP 409 with a Vietnamese message indicating the order was recently updated and prompting the user to reload.
