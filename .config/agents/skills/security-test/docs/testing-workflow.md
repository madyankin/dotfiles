# Security Testing Workflow

Systematic approach to penetration testing web applications and APIs.

## Phase 1: Preparation

### 1.1 Scope Definition

Document before starting:

```markdown
## Test Scope

**Target**: [Application name and URL]
**Environment**: [Production/Staging/Dev]
**Period**: [Start date] - [End date]

### In Scope
- [ ] API endpoints: [List or "all under /api"]
- [ ] Authentication flows
- [ ] User roles: [admin, user, etc.]
- [ ] Specific features: [List]

### Out of Scope
- [ ] Third-party integrations
- [ ] DoS/DDoS testing
- [ ] Social engineering
- [ ] Physical security

### Credentials Provided
- Test user: [email/password]
- Admin user: [email/password] (if applicable)
- API tokens: [redacted]

### Rules of Engagement
- Notify before destructive tests
- Don't access real user data
- Report critical findings immediately
```

### 1.2 Environment Setup

```bash
# Required tools
brew install httpie jq curl
pip install sqlmap  # SQL injection testing

# Set up test variables
export API_URL="https://api.staging.example.com"
export TOKEN="your_test_token"
export AUTH_HEADER="Authorization: Token token=$TOKEN"

# Verify access
curl -s "$API_URL/health" | jq .
curl -s -H "$AUTH_HEADER" "$API_URL/resources" | jq .
```

### 1.3 Endpoint Discovery

```bash
# From documentation
curl -s "$API_URL/swagger.json" | jq '.paths | keys[]'

# From application code (Rails)
rails routes | grep api

# From proxy logs (Burp Suite, mitmproxy)
# Export and analyze captured endpoints

# From frontend source
grep -rh "fetch\|axios\|api" src/ | grep -oP '"/[^"]*"' | sort -u
```

## Phase 2: Reconnaissance

### 2.1 Technology Fingerprinting

```bash
# Server headers
curl -I "$API_URL/" 2>/dev/null | grep -i "server\|x-powered-by\|x-runtime"

# Error message analysis
curl "$API_URL/nonexistent" | jq .

# Framework detection
# Rails: X-Runtime header, /rails/info/routes (dev)
# Django: /admin/, CSRF token format
# Express: X-Powered-By: Express
```

### 2.2 Authentication Analysis

```bash
# Capture auth request/response
curl -v -X POST "$API_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@test.com", "password": "password"}}'

# Analyze token
# JWT? Decode at jwt.io
# Session cookie? Check flags (Secure, HttpOnly, SameSite)
# API key? Check format, entropy
```

### 2.3 Authorization Mapping

```bash
# Create test accounts at different permission levels
# Test user 1: Regular user in Tenant A
# Test user 2: Regular user in Tenant B
# Test user 3: Admin user in Tenant A

# Document resource ownership
# Resource 123 → Tenant A
# Resource 456 → Tenant B
```

## Phase 3: Systematic Testing

### 3.1 Endpoint-by-Endpoint Testing

For each endpoint, test:

```bash
# 1. Without authentication
curl "$API_URL/resources"

# 2. With valid auth
curl -H "$AUTH_HEADER" "$API_URL/resources"

# 3. IDOR - access other users' resources
curl -H "$AUTH_HEADER" "$API_URL/resources/OTHER_TENANT_RESOURCE_ID"

# 4. HTTP method tampering
curl -X PUT -H "$AUTH_HEADER" "$API_URL/resources/123" -d '{"name": "test"}'
curl -X DELETE -H "$AUTH_HEADER" "$API_URL/resources/123"

# 5. Parameter tampering
curl -H "$AUTH_HEADER" "$API_URL/resources?tenant_id=OTHER_TENANT"

# 6. Input validation
curl -H "$AUTH_HEADER" "$API_URL/resources" \
  -d '{"name": "<script>alert(1)</script>"}'
```

### 3.2 Testing Matrix

Create a matrix for systematic coverage:

| Endpoint | Method | Auth | IDOR | Injection | Mass Assign | Notes |
|----------|--------|------|------|-----------|-------------|-------|
| /resources | GET | ✅ | ⏳ | N/A | N/A | |
| /resources | POST | ⏳ | N/A | ⏳ | ⏳ | |
| /resources/:id | GET | ✅ | ⏳ | N/A | N/A | |
| /resources/:id | PATCH | ⏳ | ⏳ | ⏳ | ⏳ | |
| /resources/:id | DELETE | ⏳ | ⏳ | N/A | N/A | |

Legend: ✅ Tested/Secure, ❌ Vulnerable, ⏳ Pending, N/A Not Applicable

### 3.3 Batch Testing Scripts

```bash
#!/bin/bash
# test_idor.sh - Test IDOR on resource endpoints

RESOURCE_IDS=("123" "456" "789")  # IDs from different tenants
ENDPOINTS=("/resources" "/users" "/tenants")

for endpoint in "${ENDPOINTS[@]}"; do
  for id in "${RESOURCE_IDS[@]}"; do
    echo "Testing $endpoint/$id"
    response=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "$AUTH_HEADER" \
      "$API_URL$endpoint/$id")
    echo "  Status: $response"
  done
done
```

## Phase 4: Documentation

### 4.1 Finding Documentation

For each finding:

```markdown
## [ID] [Title]

**Severity**: Critical/High/Medium/Low/Info
**CVSS Score**: X.X (if applicable)
**CWE**: CWE-XXX
**OWASP Category**: API1/API2/etc.

### Description
[What is the vulnerability]

### Affected Endpoint
`METHOD /path/to/endpoint`

### Impact
- Confidentiality: [Description]
- Integrity: [Description]
- Availability: [Description]

### Proof of Concept

**Request**:
```http
GET /api/vulnerable/endpoint HTTP/1.1
Host: api.example.com
Authorization: Token token=xxx
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"sensitive": "data"}
```

### Remediation
[Specific fix recommendation]

### References
- [Link to OWASP/CWE]
```

### 4.2 Session Tracking

Keep a log:

```markdown
## Testing Log - 2024-01-15

### 09:00 - Started testing
- Set up test environment
- Verified credentials work

### 10:30 - Authentication Testing
- [x] Brute force protection: Rate limited after 5 attempts ✅
- [x] Token expiration: Tokens expire after 24h ✅
- [ ] Token invalidation on logout: **VULNERABLE** - token still works
  - Filed as FINDING-001

### 14:00 - IDOR Testing
- Resource endpoints: Properly scoped to tenant ✅
- User endpoints: Can access other users in same tenant **VULNERABLE**
  - Filed as FINDING-002
```

## Phase 5: Reporting

### 5.1 Executive Summary

```markdown
## Executive Summary

A security assessment of [Application] was conducted from [date] to [date].

### Key Statistics
- Endpoints tested: X
- Findings identified: X
  - Critical: X
  - High: X
  - Medium: X
  - Low: X

### Key Risks
1. [Most critical finding summary]
2. [Second most critical finding summary]
3. [Third most critical finding summary]

### Overall Assessment
[1-2 paragraph assessment of security posture]

### Recommended Priority Actions
1. [Immediate action 1]
2. [Immediate action 2]
3. [Short-term action]
```

### 5.2 Technical Report Structure

```markdown
1. Executive Summary
2. Scope and Methodology
3. Findings Summary Table
4. Detailed Findings
   - Critical Findings
   - High Findings
   - Medium Findings
   - Low Findings
   - Informational
5. Remediation Roadmap
6. Appendix
   - Testing Tools
   - Raw Requests/Responses
```

## Tools Reference

| Tool | Purpose |
|------|---------|
| curl/httpie | Manual API testing |
| Burp Suite | Proxy, interceptor, scanner |
| sqlmap | Automated SQL injection |
| ffuf | Fuzzing, directory discovery |
| jwt_tool | JWT manipulation |
| nuclei | Vulnerability scanning |
| mitmproxy | Traffic interception |

## Quick Reference Commands

```bash
# Pretty print JSON response
curl -s "$API_URL/endpoint" | jq .

# Save response with headers
curl -i -o response.txt "$API_URL/endpoint"

# Timing attack detection
time curl "$API_URL/login" -d '{"email": "exists@test.com"}'
time curl "$API_URL/login" -d '{"email": "noexist@test.com"}'

# Follow redirects
curl -L "$API_URL/endpoint"

# Send raw request from file
curl -d @request.json "$API_URL/endpoint"

# Parallel requests
seq 1 10 | xargs -P 10 -I {} curl "$API_URL/endpoint"
```
