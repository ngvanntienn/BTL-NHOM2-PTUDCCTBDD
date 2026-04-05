# Flutter + Firebase Architecture (Seller Features)

## 1) Architecture Layers

- UI Layer: screens in `lib/screens/home` and `lib/screens/seller`
- Domain/Data Models: `lib/models/seller`
- Repository Layer: `lib/repositories`
- Service Layer: `lib/services`

Data flow:
1. Screen listens to Firestore stream from Repository.
2. Repository maps Firestore documents into typed models.
3. User actions call Repository methods for CRUD and status updates.
4. Firestore snapshots push realtime updates back to UI.

## 2) Firestore Collections Design

### users
- userId: string
- name: string
- email: string
- role: string (`user` | `seller` | `admin`)
- phone: string
- address: string
- createdAt: timestamp

### categories
- name: string
- imageUrl: string
- createdAt: timestamp

### foods
- name: string
- description: string
- price: number
- imageUrl: string
- categoryId: string
- sellerId: string
- rating: number
- isAvailable: bool
- stock: number
- createdAt: timestamp
- updatedAt: timestamp

Rule implemented:
- If `stock <= 0`, item is automatically hidden from selling (`isAvailable = false`).

### orders
- userId: string
- sellerId: string
- userName: string
- userPhone: string
- shippingAddress: string
- status: string (`pending`, `accepted`, `preparing`, `shipping`, `delivered`, `rejected`, `cancelled`)
- totalPrice: number
- items: array of map
  - foodId: string
  - foodName: string
  - imageUrl: string
  - quantity: number
  - unitPrice: number
- createdAt: timestamp
- updatedAt: timestamp

### reviews
- userId: string
- foodId: string
- rating: number
- comment: string
- createdAt: timestamp

### favorites
- userId: string
- foodId: string
- createdAt: timestamp

## 3) Seller Feature Modules

- Seller Dashboard: `lib/screens/home/seller_home.dart`
- Food Management: `lib/screens/seller/food_management_screen.dart`
- Add/Edit Food: `lib/screens/seller/add_edit_food_screen.dart`
- Order Management: `lib/screens/seller/order_management_screen.dart`

## 4) Image Upload Strategy

Implemented in `lib/services/image_upload_service.dart`:
1. Try Cloudinary (existing `CloudflareImageService`).
2. Fallback to Firebase Storage when Cloudinary config is missing.

## 5) Realtime Handling

- Foods: stream query by `sellerId`, ordered by `createdAt`.
- Orders: stream query by `sellerId`, ordered by `createdAt`.
- UI updates instantly via `StreamBuilder`.

## 6) Required Composite Indexes (if Firestore prompts)

Potential indexes depending on data volume/query planner:
- foods: sellerId ASC + createdAt DESC
- orders: sellerId ASC + createdAt DESC

When Firestore console shows index error, create index from the auto-generated link in log.
