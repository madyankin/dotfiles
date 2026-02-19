---
name: security-testing
description: Assist with penetration testing and security research on web applications. Analyze endpoints for vulnerabilities, test authentication/authorization, identify injection flaws, and generate security findings. Use when pentesting, security auditing, reviewing API security, or when user mentions security testing, vulnerabilities, or OWASP.
---

# Security Testing & Penetration Testing

Assist with security testing of web applications, focusing on API security, authentication, authorization, and common vulnerability patterns.

## Kali Linux Environment

A Dockerized Kali Linux environment is available for penetration testing with pre-configured tools.

### Quick Start

```bash
# Navigate to the skill directory
cd ~/.config/agents/skills/security-testing

# Start Kali container
docker compose up -d

# Enter the Kali shell
docker exec -it pentest-kali /bin/bash

# First time: run the setup script to install tools
chmod +x /pentest/../kali-setup.sh  # if needed
./kali-setup.sh
```

### Container Details

| Feature | Details |
|---------|---------|
| **Image** | `kalilinux/kali-rolling` (official Kali) |
| **Container name** | `pentest-kali` |
| **Pentest files** | Mounted at `/pentest` (Google Drive Pentest 2026 folder) |
| **Persistence** | `/root` persisted via `kali-home` volume |

### Common Commands

```bash
# Start container (if stopped)
docker compose up -d

# Enter shell
docker exec -it pentest-kali /bin/bash

# Stop container
docker compose down

# Remove container and volumes (clean slate)
docker compose down -v

# View container logs
docker logs pentest-kali
```

### Pre-installed Tools (after running kali-setup.sh)

| Category | Tools |
|----------|-------|
| **Web scanning** | Burp Suite, Nikto, Gobuster, Dirb, FFuf, Wfuzz |
| **SQL injection** | SQLMap |
| **Auth testing** | Hydra, John, Hashcat |
| **Network** | Nmap, Netcat, Tcpdump |
| **API testing** | HTTPie, curl, Python (requests, httpx, pyjwt) |

### Example Workflow

```bash
# 1. Start Kali
docker exec -it pentest-kali /bin/bash

# 2. Navigate to pentest files
cd /pentest

# 3. Run a scan
nikto -h https://target-api.example.com

# 4. Test for SQL injection
sqlmap -u "https://api.example.com/search?q=test" --batch

# 5. Directory enumeration
gobuster dir -u https://api.example.com -w /usr/share/wordlists/dirb/common.txt

# 6. Results are saved in /pentest (synced to Google Drive)
```

### Network Scanning (Advanced)

For tools requiring raw socket access (nmap SYN scans, etc.), uncomment the `cap_add` section in `docker-compose.yml`:

```yaml
cap_add:
  - NET_RAW
  - NET_ADMIN
```

Then restart: `docker compose down && docker compose up -d`

---

## When to Use

- Pentesting web applications or APIs
- Analyzing endpoints for security vulnerabilities
- Testing authentication and authorization controls
- Identifying injection flaws (SQL, NoSQL, command injection)
- Reviewing API security configurations
- Generating security findings and reports

## Quick Start

### 1. Scope Assessment

Before testing, understand:
- What endpoints are in scope?
- What authentication mechanism is used?
- What's the authorization model (roles, organizations, multi-tenant)?
- Are there any out-of-scope areas?

### 2. Testing Checklist

Copy and track progress:

```
Security Testing Progress:
- [ ] Authentication Testing
  - [ ] Brute force protection
  - [ ] Session management
  - [ ] Token security (JWT/API keys)
  - [ ] Password policies
- [ ] Authorization Testing
  - [ ] IDOR (Insecure Direct Object Reference)
  - [ ] Privilege escalation (horizontal/vertical)
  - [ ] Missing function-level access control
- [ ] Injection Testing
  - [ ] SQL injection
  - [ ] NoSQL injection
  - [ ] Command injection
  - [ ] LDAP injection
- [ ] Input Validation
  - [ ] XSS (reflected, stored, DOM)
  - [ ] Path traversal
  - [ ] File upload vulnerabilities
- [ ] Business Logic
  - [ ] Rate limiting bypass
  - [ ] Workflow bypass
  - [ ] Mass assignment
- [ ] Information Disclosure
  - [ ] Error messages
  - [ ] Debug endpoints
  - [ ] Sensitive data in responses
```

## Testing Methodology

### Phase 1: Reconnaissance

1. **Endpoint Discovery**: List all API endpoints, methods, and parameters
2. **Authentication Analysis**: Identify auth mechanisms and token formats
3. **Authorization Model**: Map roles, permissions, and resource ownership
4. **Technology Stack**: Identify frameworks, libraries, versions

### Phase 2: Systematic Testing

Test each endpoint category:

| Category | Key Tests |
|----------|-----------|
| Auth endpoints (`/sign_in`, `/sign_up`) | Brute force, credential stuffing, account enumeration |
| Resource endpoints (`/resources/:id`) | IDOR, missing auth, privilege escalation |
| Search/filter endpoints | Injection, information disclosure |
| File operations | Upload bypass, path traversal |
| Admin endpoints | Access control, privilege escalation |

### Phase 3: Exploitation & Validation

For each finding:
1. Confirm the vulnerability is exploitable
2. Assess the impact (confidentiality, integrity, availability)
3. Document reproduction steps
4. Suggest remediation

## Common Attack Patterns

### Authentication Bypass

```bash
# Test missing auth
curl -X GET "https://api.example.com/admin/users" \
  -H "Accept: application/json"

# Test with invalid token
curl -X GET "https://api.example.com/resources" \
  -H "Authorization: Token token=invalid123" \
  -H "Accept: application/json"

# Test token in different locations
curl -X GET "https://api.example.com/resources?token=VALID_TOKEN"
```

### IDOR Testing

```bash
# Access another user's resource
curl -X GET "https://api.example.com/resources/OTHER_USER_RESOURCE_ID" \
  -H "Authorization: Token token=MY_TOKEN"

# Modify another user's resource
curl -X PATCH "https://api.example.com/resources/OTHER_USER_RESOURCE_ID" \
  -H "Authorization: Token token=MY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Hacked"}'

# Delete another user's resource
curl -X DELETE "https://api.example.com/resources/OTHER_USER_RESOURCE_ID" \
  -H "Authorization: Token token=MY_TOKEN"
```

### SQL Injection

```bash
# Test in query parameters
curl "https://api.example.com/search?q=' OR '1'='1"
curl "https://api.example.com/search?q='; DROP TABLE users;--"

# Test in JSON body
curl -X POST "https://api.example.com/resources" \
  -H "Content-Type: application/json" \
  -d '{"name": "test'\'' OR '\''1'\''='\''1"}'

# Test in path parameters
curl "https://api.example.com/users/1 OR 1=1"
```

### Mass Assignment

```bash
# Try to set admin flag
curl -X POST "https://api.example.com/users" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "admin": true}'

# Try to modify organization_id
curl -X PATCH "https://api.example.com/resources/123" \
  -H "Content-Type: application/json" \
  -d '{"organization_id": "OTHER_ORG_ID"}'
```

## Rails-Specific Security

For Rails applications, check:

### Strong Parameters Bypass

```bash
# Test unpermitted nested attributes
curl -X POST "https://api.example.com/resources" \
  -d '{"resource": {"user_attributes": {"admin": true}}}'

# Test array parameter pollution
curl "https://api.example.com/resources?ids[]=1&ids[]=2;DROP TABLE"
```

### Session/Token Issues

```bash
# Check token doesn't change after password reset
# Check for session fixation
# Verify token invalidation on logout
```

### Common Rails Vulnerabilities

- `permit!` usage (allows all parameters)
- Missing `protect_from_forgery` for non-API routes
- Unsafe YAML deserialization
- SQL injection via `find_by_sql`, `where` with strings
- Command injection via `system`, backticks, `exec`

## Reporting Findings

### Finding Template

```markdown
## [SEVERITY] [Title]

**Affected Endpoint**: `METHOD /path`

**Description**: 
[What the vulnerability is and why it matters]

**Impact**:
- Confidentiality: [High/Medium/Low/None]
- Integrity: [High/Medium/Low/None]
- Availability: [High/Medium/Low/None]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]
3. [Observe result]

**Proof of Concept**:
```bash
curl -X GET "https://api.example.com/vulnerable/endpoint" \
  -H "Authorization: Token token=..." \
  -d '{"payload": "..."}'
```

**Response**:
```json
{"sensitive_data": "exposed"}
```

**Remediation**:
[Specific fix recommendation]

**References**:
- [CWE-XXX](https://cwe.mitre.org/data/definitions/XXX.html)
- [OWASP Link]
```

### Severity Ratings

| Severity | Criteria |
|----------|----------|
| **Critical** | Remote code execution, auth bypass affecting all users, data breach of all records |
| **High** | Privilege escalation, access to other users' data, significant data modification |
| **Medium** | Limited data exposure, denial of service, security misconfiguration |
| **Low** | Information disclosure (non-sensitive), missing best practices |
| **Info** | Observations, hardening recommendations |

## Additional Resources

- **Kali Docker setup**: [docker-compose.yml](docker-compose.yml), [kali-setup.sh](kali-setup.sh)
- For OWASP API Top 10, see [docs/owasp-api-top10.md](docs/owasp-api-top10.md)
- For Rails-specific security, see [docs/rails-security.md](docs/rails-security.md)
- For testing workflow, see [docs/testing-workflow.md](docs/testing-workflow.md)

## Output Format

When reporting findings, structure as:

```markdown
## Security Assessment Summary

**Scope**: [Endpoints/features tested]
**Duration**: [Testing period]
**Methodology**: [Tools and approach]

## Executive Summary
[1-2 paragraphs on overall security posture and key risks]

## Findings by Severity

### Critical (X)
[List critical findings]

### High (X)
[List high findings]

### Medium (X)
[List medium findings]

### Low (X)
[List low findings]

## Recommendations
[Prioritized remediation guidance]
```
