# Rails-Specific Security Testing

Security testing considerations specific to Ruby on Rails applications.

## Authentication & Session Management

### Token-Based Auth Testing

```bash
# Test token format and entropy
# Good tokens: 20+ chars, alphanumeric, random
# Bad tokens: sequential, predictable, base64-encoded user info

# Token in multiple locations
curl -H "Authorization: Token token=XXX"
curl -H "X-API-Token: XXX"
curl "?api_token=XXX"
curl -b "api_token=XXX"

# Token reuse after logout
curl -X DELETE /users/sign_out -H "Authorization: Token token=XXX"
curl /resources -H "Authorization: Token token=XXX"  # Should fail

# Token reuse after password change
# Get token, change password, try old token
```

### Devise-Specific Tests

```bash
# Account enumeration via registration
POST /users -d '{"email": "existing@test.com", "password": "test123"}'
# Response: "Email has already been taken" = account exists

# Account enumeration via password reset
POST /users/password -d '{"email": "test@test.com"}'
# Different response for existing vs non-existing = enumeration

# Confirmable bypass
POST /users -d '{"email": "test@test.com", "confirmed_at": "2024-01-01"}'
```

## Authorization (Pundit/CanCanCan)

### Policy Bypass

```bash
# Test each CRUD action independently
# Policies might allow :index but not :show

# Test scope leakage
GET /resources  # Should only return user's resources
# Check if response includes other tenants' data

# Test nested resource authorization
GET /tenants/OTHER_TENANT/resources  # Cross-tenant access
DELETE /tenants/MY_TENANT/resources/OTHER_TENANT_RESOURCE
```

### Common Auth Flaws

```ruby
# ❌ Vulnerable: No authorization
def show
  @resource = Resource.find(params[:id])
end

# ❌ Vulnerable: Authorization after fetch
def show
  @resource = Resource.find(params[:id])
  authorize @resource  # Already exposed data in logs/errors
end

# ✅ Secure: Scoped query
def show
  @resource = current_user.tenant.resources.find(params[:id])
end
```

## Injection Vulnerabilities

### SQL Injection

```ruby
# ❌ Vulnerable patterns to test:
Resource.where("name = '#{params[:name]}'")
Resource.where("name = ?" + params[:name])
Resource.find_by_sql("SELECT * FROM resources WHERE name = '#{params[:name]}'")
Resource.order(params[:sort])  # ORDER BY injection

# Test payloads:
params[:name] = "' OR '1'='1"
params[:name] = "'; DROP TABLE resources;--"
params[:sort] = "name; DROP TABLE resources;--"
params[:sort] = "(SELECT password FROM users LIMIT 1)"
```

### Command Injection

```ruby
# ❌ Vulnerable patterns:
system("convert #{params[:file]}")
`ls #{params[:path]}`
exec("ping #{params[:host]}")
IO.popen("cat #{params[:filename]}")
Open3.capture3("grep #{params[:pattern]} file.txt")

# Test payloads:
params[:file] = "image.png; cat /etc/passwd"
params[:host] = "8.8.8.8; whoami"
params[:pattern] = "; rm -rf /"
```

### Path Traversal

```ruby
# ❌ Vulnerable patterns:
File.read("uploads/#{params[:filename]}")
send_file(Rails.root.join('files', params[:path]))

# Test payloads:
params[:filename] = "../../../etc/passwd"
params[:path] = "....//....//....//etc/passwd"
params[:filename] = "..%2f..%2f..%2fetc%2fpasswd"  # URL encoded
```

## Mass Assignment

### Strong Parameters Bypass

```bash
# Test unpermitted attributes
POST /resources -d '{"resource": {"admin_approved": true}}'
POST /users -d '{"user": {"admin": true, "role": "superuser"}}'

# Test nested attributes
POST /resources -d '{"resource": {"tenant_attributes": {"billing_code": "FREE"}}}'

# Test array parameters
POST /resources -d '{"resource": {"tag_ids": [1, 2, "'; DROP TABLE tags;--"]}}'
```

### Common Vulnerable Patterns

```ruby
# ❌ Dangerous: permit!
def resource_params
  params.require(:resource).permit!
end

# ❌ Dangerous: Hash type (allows any keys)
def resource_params
  params.require(:resource).permit(:name, metadata: {})
end

# ❌ Vulnerable: Nested association not scoped
def resource_params
  params.require(:resource).permit(:name, tenant_id: :any)
end
```

## Serialization

### Unsafe Deserialization

```ruby
# ❌ Vulnerable to RCE:
YAML.load(params[:data])
Marshal.load(params[:data])

# Test with crafted YAML payload that executes code
# (Use ysoserial or similar for payload generation)
```

### API Response Leakage

```bash
# Check if serializers expose sensitive data
GET /api/users/me

# Response might include:
# - password_digest
# - remember_token
# - api_keys
# - internal_notes
# - other_users (via eager loading)
```

## File Upload

### Bypass Techniques

```bash
# Content-Type bypass
curl -F "file=@shell.php;type=image/png" /upload

# Extension bypass
curl -F "file=@shell.php.png" /upload
curl -F "file=@shell.php%00.png" /upload  # Null byte
curl -F "file=@shell.pHp" /upload  # Case variation

# Magic bytes bypass
# Add PNG header to PHP file
```

### Dangerous Configurations

```ruby
# ❌ Vulnerable: No validation
def upload
  File.write("public/uploads/#{params[:file].original_filename}", params[:file].read)
end

# Check if uploaded files are served with correct Content-Type
# Check if uploads directory allows script execution
```

## Security Headers

Check response headers:

```bash
curl -I https://api.example.com/

# Expected headers:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY or SAMEORIGIN
# X-XSS-Protection: 1; mode=block
# Strict-Transport-Security: max-age=31536000
# Content-Security-Policy: ...
```

## Logging & Error Handling

### Information Disclosure

```bash
# Trigger errors and check responses
GET /api/resources/9999999999999999
GET /api/resources/invalid-uuid-format
POST /api/resources -d '{"invalid": "json'

# Check if responses include:
# - Stack traces
# - SQL queries
# - Internal paths
# - Framework versions
```

### Sensitive Data Logging

Check logs for:
- Passwords
- API tokens
- Credit card numbers
- Personal data

Rails default filters: check `config/initializers/filter_parameter_logging.rb`

## Testing Checklist

```
Rails Security Testing:
- [ ] Token auth: entropy, expiration, invalidation
- [ ] Devise: enumeration, confirmation bypass
- [ ] Authorization: IDOR, scope leakage, policy bypass
- [ ] SQL injection: where clauses, order, find_by_sql
- [ ] Command injection: system, backticks, exec
- [ ] Path traversal: file operations
- [ ] Mass assignment: permit!, nested attrs, hash type
- [ ] Deserialization: YAML.load, Marshal.load
- [ ] File upload: type bypass, path traversal, RCE
- [ ] Error handling: stack traces, info disclosure
- [ ] Security headers: HSTS, CSP, X-Frame-Options
- [ ] Logging: sensitive data filtering
```
