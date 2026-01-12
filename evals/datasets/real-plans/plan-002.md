# Test Plan 2

## Prompt
Plan a basic REST API for CRUD operations on a todo list

## Generated Plan
# Implementation Plan: Todo List REST API

## 1. Overview

A simple REST API service for managing a todo list with full CRUD (Create, Read, Update, Delete) operations. The API will allow users to create todos, retrieve them (individually or as a list), update their status and content, and delete them. This will be implemented as a single, straightforward backend service with persistent storage.

**Technology Stack:**
- **Runtime:** Node.js with Express.js (simple, well-documented, ideal for REST APIs)
- **Database:** SQLite (file-based, zero configuration, perfect for todo apps)
- **Validation:** Express-validator (built-in request validation)
- **Testing:** Jest + Supertest (API endpoint testing)

## 2. Project Structure

### Project 1: Todo API Service
**Single monolithic backend service** - All API logic, data access, and business rules in one deployable unit.

**Rationale:** A todo list CRUD API is a straightforward application with no complex domain separation. Splitting into multiple services would introduce unnecessary complexity, deployment overhead, and inter-service communication without any real benefit.

---

## 3. Project Details

### Project 1: Todo API Service

#### Scope and Boundaries
- RESTful API endpoints for todo management
- Data persistence layer (SQLite database)
- Input validation and error handling
- Basic logging for debugging
- API documentation (inline comments + README)

#### File Structure
```
todo-api/
├── src/
│   ├── index.js              # Entry point, server setup
│   ├── routes/
│   │   └── todos.js          # Todo route handlers
│   ├── models/
│   │   └── todo.js           # Data access layer
│   ├── middleware/
│   │   ├── validation.js     # Request validators
│   │   └── errorHandler.js   # Global error handling
│   └── db/
│       └── database.js       # Database initialization
├── tests/
│   └── todos.test.js         # API endpoint tests
├── package.json
├── .env.example
└── README.md
```

#### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos` | Get all todos (with optional filters: ?completed=true) |
| GET | `/api/todos/:id` | Get a specific todo by ID |
| POST | `/api/todos` | Create a new todo |
| PUT | `/api/todos/:id` | Update an existing todo |
| DELETE | `/api/todos/:id` | Delete a todo |

#### Data Model
```javascript
Todo {
  id: INTEGER (auto-increment, primary key)
  title: TEXT (required, max 200 chars)
  description: TEXT (optional, max 1000 chars)
  completed: BOOLEAN (default: false)
  createdAt: DATETIME (auto-generated)
  updatedAt: DATETIME (auto-updated)
}
```

#### Key Tasks and Milestones

**Phase 1: Foundation (Day 1)**
- [ ] Initialize Node.js project with Express
- [ ] Set up SQLite database connection
- [ ] Create todos table schema with migration
- [ ] Implement basic server with health check endpoint (`/health`)
- [ ] Configure environment variables (port, database path)

**Phase 2: Core CRUD Operations (Day 2)**
- [ ] Implement POST `/api/todos` - Create todo
- [ ] Implement GET `/api/todos` - List all todos
- [ ] Implement GET `/api/todos/:id` - Get single todo
- [ ] Implement PUT `/api/todos/:id` - Update todo
- [ ] Implement DELETE `/api/todos/:id` - Delete todo
- [ ] Add data access layer for database operations

**Phase 3: Validation & Error Handling (Day 3)**
- [ ] Add input validation middleware (title required, length limits)
- [ ] Implement global error handler
- [ ] Add 404 handling for non-existent resources
- [ ] Validate ID parameters (numeric, exists in DB)
- [ ] Return appropriate HTTP status codes (200, 201, 400, 404, 500)

**Phase 4: Testing & Documentation (Day 4)**
- [ ] Write unit tests for data access layer
- [ ] Write integration tests for all API endpoints
- [ ] Test error scenarios (invalid input, missing resources)
- [ ] Document API endpoints in README
- [ ] Add example requests/responses

#### Dependencies
- **External:** None (standalone service)
- **NPM Packages:**
  - `express` - Web framework
  - `better-sqlite3` - Synchronous SQLite client
  - `express-validator` - Request validation
  - `dotenv` - Environment configuration
  - `jest` & `supertest` - Testing (dev dependencies)

#### Testing Strategy

**Unit Tests:**
- Database operations (CRUD functions in isolation)
- Validation logic
- Error handling utilities

**Integration Tests:**
- Full request/response cycle for each endpoint
- Test successful operations (200, 201 responses)
- Test error cases (400, 404 responses)
- Test edge cases (empty list, updating non-existent todo)
- Test query parameters (filtering by completed status)

**Test Coverage Goals:**
- Minimum 80% code coverage
- 100% endpoint coverage
- All error paths tested

**Testing Tools:**
```bash
# Run all tests
npm test

# Run with coverage report
npm run test:coverage

# Run in watch mode during development
npm run test:watch
```

---

## 4. Development Approach

### Phasing Strategy

**Phase 1: MVP (Minimum Viable Product) - Days 1-2**
- Basic CRUD operations working
- Data persists in SQLite
- Manual testing via Postman/curl
- **Deliverable:** Functional API with all endpoints

**Phase 2: Hardening - Days 3-4**
- Add validation and error handling
- Write comprehensive tests
- Document API
- **Deliverable:** Production-ready service with tests

**Phase 3: Enhancements (Optional/Future)**
- Add pagination for GET `/api/todos`
- Add search/filter capabilities
- Add due dates to todos
- Add priority levels

### Development Workflow
1. Create feature branch from `main`
2. Implement functionality
3. Write tests (aim for test-first when possible)
4. Run tests locally (`npm test`)
5. Manual testing with REST client
6. Merge to `main` when tests pass

### Deployment Strategy

**Local Development:**
```bash
npm install
npm run dev  # Uses nodemon for auto-reload
```

**Production Deployment:**
```bash
npm install --production
npm start
```

**Environment Configuration:**
- `PORT` - Server port (default: 3000)
- `DATABASE_PATH` - SQLite file location (default: `./todos.db`)
- `NODE_ENV` - Environment (development/production)

**Deployment Options:**
- **Simple:** Run directly on VPS with PM2 process manager
- **Containerized:** Docker container (single Dockerfile)
- **Platform:** Deploy to Heroku, Railway, or Render (all support Node.js natively)

**Docker Setup (Optional):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY src/ ./src/
EXPOSE 3000
CMD ["node", "src/index.js"]
```

---

## 5. Verification Steps

### Project 1: Todo API Service

#### Functional Verification

**Step 1: Health Check**
```bash
curl http://localhost:3000/health
# Expected: {"status": "ok"}
```

**Step 2: Create Todo**
```bash
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Test todo", "description": "Test description"}'
# Expected: 201 status, returns created todo with ID
```

**Step 3: List Todos**
```bash
curl http://localhost:3000/api/todos
# Expected: 200 status, array containing created todo
```

**Step 4: Get Single Todo**
```bash
curl http://localhost:3000/api/todos/1
# Expected: 200 status, returns todo with ID 1
```

**Step 5: Update Todo**
```bash
curl -X PUT http://localhost:3000/api/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
# Expected: 200 status, returns updated todo
```

**Step 6: Delete Todo**
```bash
curl -X DELETE http://localhost:3000/api/todos/1
# Expected: 204 status, no content
```

**Step 7: Verify Deletion**
```bash
curl http://localhost:3000/api/todos/1
# Expected: 404 status, error message
```

#### Error Handling Verification

**Test Invalid Input:**
```bash
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: 400 status, validation error for missing title
```

**Test Non-existent Resource:**
```bash
curl http://localhost:3000/api/todos/99999
# Expected: 404 status, "Todo not found" message
```

**Test Invalid ID:**
```bash
curl http://localhost:3000/api/todos/invalid
# Expected: 400 status, "Invalid ID" message
```

#### Automated Testing Verification

```bash
# Run test suite
npm test

# Expected output:
# ✓ GET /api/todos returns empty array initially
# ✓ POST /api/todos creates new todo
# ✓ POST /api/todos validates required fields
# ✓ GET /api/todos/:id returns todo
# ✓ GET /api/todos/:id returns 404 for non-existent
# ✓ PUT /api/todos/:id updates todo
# ✓ DELETE /api/todos/:id removes todo
# ... (all tests passing)
```

#### Performance Verification (Basic)

```bash
# Test response time for list endpoint
time curl http://localhost:3000/api/todos
# Expected: < 100ms for small datasets

# Create 100 todos and test performance
for i in {1..100}; do
  curl -X POST http://localhost:3000/api/todos \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Todo $i\"}" &
done
wait

time curl http://localhost:3000/api/todos
# Expected: < 500ms for 100 items
```

#### Data Persistence Verification

```bash
# Create a todo
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Persistence test"}'

# Stop server
# Restart server

# Verify todo still exists
curl http://localhost:3000/api/todos
# Expected: Previously created todo is still in the list
```

---

## 6. Success Criteria

The implementation is considered complete when:

- ✅ All 5 CRUD endpoints are functional
- ✅ Data persists across server restarts
- ✅ Input validation prevents invalid data
- ✅ Appropriate HTTP status codes are returned
- ✅ All automated tests pass (minimum 80% coverage)
- ✅ API documentation is complete in README
- ✅ Error handling covers common failure scenarios
- ✅ Manual verification steps all pass
- ✅ Service can be deployed and run in production environment

---

## 7. Timeline Estimate

**Total Duration:** 4 days (assuming 1 developer working full-time)

- **Day 1:** Project setup, database, basic server (Phase 1 Foundation)
- **Day 2:** Implement all CRUD endpoints (Phase 2 Core Operations)
- **Day 3:** Add validation, error handling (Phase 3 Hardening)
- **Day 4:** Testing, documentation, verification (Phase 4 Testing)

**Note:** This is a conservative estimate. An experienced developer could complete this in 2-3 days.

---

## 8. Future Enhancements (Out of Scope)

These are explicitly NOT part of the initial implementation but could be added later:

- User authentication and authorization
- Multiple todo lists per user
- Tags/categories for todos
- Due dates and reminders
- File attachments
- Real-time updates (WebSocket)
- Frontend web application
- Mobile app

**Principle:** Ship the simple version first, validate usage, then enhance based on actual needs.

## Review Notes
<!-- Domain expert notes go here during error analysis -->
- [ ] Pass/Fail: Pass (from automated eval)
- [ ] Issues found:
- [ ] Failure category:
