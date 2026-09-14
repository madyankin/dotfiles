# OWASP API Security Top 10 (2023)

Quick reference for API security testing based on OWASP API Security Top 10.

## API1: Broken Object Level Authorization (BOLA)

**What**: APIs expose endpoints handling object IDs, creating wide attack surface for IDOR.

**Test**:
```bash
# Access resource owned by another user
GET /api/resources/{OTHER_USER_ID}
PATCH /api/resources/{OTHER_USER_ID}
DELETE /api/resources/{OTHER_USER_ID}
```

**Indicators**:
- Predictable/sequential IDs
- No ownership check on resource access
- Organization/tenant boundaries not enforced

**Fix**: Always verify user owns/has access to the resource before operations.

---

## API2: Broken Authentication

**What**: Weak authentication mechanisms allow attackers to compromise tokens or exploit flaws.

**Test**:
```bash
# Brute force
for i in {1..1000}; do
  curl -X POST /sign_in -d '{"email":"victim@test.com","password":"pass'$i'"}'
done

# Token analysis
# Check if JWT uses weak algorithm (alg: none, HS256 with weak secret)
# Check token expiration, rotation, invalidation
```

**Indicators**:
- No rate limiting on auth endpoints
- Tokens don't expire or have long lifetime
- Tokens not invalidated on logout/password change
- Weak token generation (predictable)

**Fix**: Implement rate limiting, strong token generation, proper expiration.

---

## API3: Broken Object Property Level Authorization

**What**: APIs expose object properties that should be restricted.

**Test**:
```bash
# Mass assignment - set unauthorized fields
POST /api/users -d '{"email":"test@test.com", "admin": true, "balance": 1000000}'

# Excessive data exposure - check response for sensitive fields
GET /api/users/me
# Response includes: password_hash, api_keys, internal_notes
```

**Indicators**:
- Response includes more data than needed
- Can set fields not shown in UI
- No allowlist for writable properties

**Fix**: Use allowlists for both readable and writable properties.

---

## API4: Unrestricted Resource Consumption

**What**: No limits on API resource usage leads to DoS or financial damage.

**Test**:
```bash
# Request large datasets
GET /api/resources?per_page=999999

# Trigger expensive operations
POST /api/reports/generate -d '{"date_range": "10_years"}'

# Concurrent requests
for i in {1..100}; do curl /api/expensive &; done
```

**Indicators**:
- No pagination limits
- No rate limiting
- Expensive operations without queueing
- No timeouts on requests

**Fix**: Implement rate limiting, pagination limits, request timeouts.

---

## API5: Broken Function Level Authorization

**What**: Complex access control leads to authorization flaws.

**Test**:
```bash
# Access admin endpoints as regular user
GET /api/admin/users
POST /api/admin/settings

# Change HTTP method
OPTIONS /api/resources  # Discover allowed methods
PUT /api/resources/123  # Try methods not exposed in UI
```

**Indicators**:
- Admin functions accessible without admin role
- HTTP method restrictions not enforced
- Authorization only on frontend, not backend

**Fix**: Deny by default, implement function-level access control.

---

## API6: Unrestricted Access to Sensitive Business Flows

**What**: Business logic can be abused at scale.

**Test**:
```bash
# Automate business flow
# Purchase flow without limits
# Comment/review spam
# Ticket scalping automation
```

**Indicators**:
- No anti-automation (CAPTCHA, rate limits)
- Monetizable flows without protection
- High-value operations without verification

**Fix**: Implement rate limiting per user, device fingerprinting, step-up auth.

---

## API7: Server Side Request Forgery (SSRF)

**What**: API fetches user-supplied URLs without validation.

**Test**:
```bash
# Internal network access
POST /api/import -d '{"url": "http://169.254.169.254/latest/meta-data/"}'
POST /api/import -d '{"url": "http://localhost:6379/"}'

# Cloud metadata
POST /api/webhook -d '{"callback_url": "http://169.254.169.254/..."}'
```

**Indicators**:
- API accepts URLs and fetches them
- Webhook/callback functionality
- Image/file import from URL

**Fix**: Validate and allowlist URLs, block internal IPs, use egress proxy.

---

## API8: Security Misconfiguration

**What**: Insecure default configurations or incomplete/improper config.

**Test**:
```bash
# Check headers
curl -I /api/endpoint
# Missing: X-Content-Type-Options, X-Frame-Options, CSP

# Debug endpoints
GET /api/debug
GET /api/health
GET /api/metrics  # Prometheus metrics exposed?

# Error messages
GET /api/resources/invalid-id
# Response: "PG::Error: column not found..." (leaks DB type)
```

**Indicators**:
- Verbose error messages
- Default credentials
- Unnecessary HTTP methods enabled
- Missing security headers
- Debug mode in production

**Fix**: Harden configuration, remove debug features, use security headers.

---

## API9: Improper Inventory Management

**What**: Old/deprecated API versions still accessible, undocumented endpoints.

**Test**:
```bash
# Version enumeration
GET /api/v1/users
GET /api/v2/users
GET /v1/users
GET /users  # Unversioned

# Documentation leaks
GET /swagger.json
GET /api-docs
GET /.well-known/openapi.json
```

**Indicators**:
- Multiple API versions active
- Beta/deprecated endpoints still work
- Undocumented endpoints accessible

**Fix**: Inventory all APIs, deprecate old versions, document and monitor.

---

## API10: Unsafe Consumption of APIs

**What**: Trusting third-party API data without validation.

**Test**:
- Identify third-party API integrations
- Check if responses are validated/sanitized
- Test for injection via third-party data

**Indicators**:
- Third-party data rendered without sanitization
- No validation of external API responses
- Redirects based on external data

**Fix**: Validate all external data, don't trust third-party responses.

---

## Testing Priority Matrix

| Vulnerability | Likelihood | Impact | Priority |
|---------------|------------|--------|----------|
| API1 (BOLA) | High | High | **Critical** |
| API2 (Broken Auth) | High | Critical | **Critical** |
| API3 (Property Auth) | High | Medium | **High** |
| API5 (Function Auth) | Medium | High | **High** |
| API4 (Resource) | Medium | Medium | **Medium** |
| API6 (Business Logic) | Medium | Variable | **Medium** |
| API7 (SSRF) | Low | High | **Medium** |
| API8 (Misconfig) | High | Low-Med | **Medium** |
| API9 (Inventory) | Medium | Low | **Low** |
| API10 (Unsafe Consumption) | Low | Medium | **Low** |
