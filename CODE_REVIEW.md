# leaStudios Plugins - Code Quality Review

**Date:** 2026-03-31
**Scope:** leastudios-forms, leastudios-mailer, leastudios-snippets
**Tools Used:** Manual code review, PHPCS (WordPress Coding Standards), PHPStan (Level 6)

---

## Executive Summary

All three plugins demonstrate **strong code quality and security fundamentals**. They consistently use `declare(strict_types=1)`, PSR-4 autoloading, proper namespacing, and modern PHP 8.1+ features. PHPCS reports **zero violations** across all three plugins. PHPStan identifies mostly type-annotation gaps (iterable value types) and a few minor logic issues.

| Plugin | Security | WP Standards | Code Quality | Overall |
|--------|----------|-------------|-------------|---------|
| leastudios-forms | Good | Excellent | Good | 8/10 |
| leastudios-mailer | Excellent | Excellent | Excellent | 9.5/10 |
| leastudios-snippets | Good | Excellent | Good | 8.5/10 |

---

## Automated Tool Results

### PHPCS (WordPress Coding Standards)
**Result: PASS** - Zero violations in all three leaStudios plugins.

### PHPStan (Level 6)
**Result: 170 errors** - Most from vendor directories. Plugin-specific issues listed below per plugin.

---

## Plugin: leastudios-forms

### What's Done Well
- All database queries use `$wpdb->prepare()` consistently
- Proper nonce verification on all form submissions
- Output escaping (`esc_html()`, `esc_attr()`, `esc_url()`) used throughout
- Stripe keys encrypted with libsodium (sodium_crypto_secretbox)
- Webhook signature verification with proper HMAC validation
- REST API has correct permission callbacks with documented rationale
- All hooks prefixed with `leastudios_forms_`
- Full i18n coverage

### Issues to Address

#### High Priority

| # | File | Issue | Detail |
|---|------|-------|--------|
| 1 | `src/Encryption/Options_Encryptor.php:83-86` | Hardcoded encryption fallbacks | Falls back to `'default-auth-key'` and `'default-salt'` if `AUTH_KEY`/`SECURE_AUTH_SALT` are undefined. This silently weakens encryption. Should throw an exception or log a critical error instead. |
| 2 | `src/REST/Payment_Intent_Controller.php` | No payment amount bounds validation | Dynamic amounts from the request are not capped. Add min/max validation (e.g., `$amount_cents = max(50, min($amount_cents, 999999900))`) to prevent abuse. |
| 3 | `src/REST/Payment_Intent_Controller.php` | No rate limiting on payment endpoint | The submission endpoint has rate limiting but the payment intent creation endpoint does not. Apply the same `Rate_Limiter` check. |

#### Medium Priority

| # | File | Issue | Detail |
|---|------|-------|--------|
| 4 | `src/Admin/Form_Editor.php:369-375` | `sanitize_text_field()` on JSON data | `sanitize_text_field()` strips newlines, potentially breaking multi-line JSON. Use `wp_unslash()` then `json_decode()` with structure validation instead. |
| 5 | `src/Submission/Submission_Handler.php:120-135` | Field names not validated as safe identifiers | Field names from admin config should use `sanitize_key()` for defense-in-depth. |
| 6 | `src/Notification/Email_Notifier.php:53-59` | Reply-To header missing `sanitize_email()` | Uses `is_email()` check (good) but should also pass through `sanitize_email()` before adding to headers. |

#### Low Priority / PHPStan

| # | File | Issue |
|---|------|-------|
| 7 | `src/Admin/Entries_Page.php:619` | `LEASTUDIOS_FORMS_URL` constant not found by PHPStan (defined at runtime) |
| 8 | `src/Admin/Form_Editor.php:406,413` | Same constant resolution issue |
| 9 | `src/Admin/Forms_Page.php:38` | Action callback returns string but should return void |
| 10 | `src/Entry/Entry_Repository.php` | Missing iterable value types on `$field_data`, `get_entries()`, `$message_ids`, `get_entries_for_export()` |
| 11 | `src/Field/Field_Type.php` | Missing iterable value types on `validate()` and `render()` `$field_config` params |
| 12 | Multiple Field Types | Same `$field_config` iterable type issue across Address, Checkbox, and other field classes |
| 13 | `src/Spam/Rate_Limiter.php:30` | Uses `md5()` for IP hashing; `hash('sha256', ...)` is more appropriate |

---

## Plugin: leastudios-mailer

### What's Done Well
- **Exemplary security implementation** across the board
- Proper sodium-based authenticated encryption for AWS credentials
- AWS SigV4 signing correctly implemented
- SNS webhook validates certificate origin (HTTPS + amazonaws.com domain) preventing SSRF
- Certificate caching with transients
- All AJAX handlers verify both nonce AND capability (`manage_options`)
- Centralized `Nonce` helper class with consistent prefixing
- Assets only enqueued on the correct admin page via `$hook_suffix` check
- Comprehensive type hints including array shapes in return types
- Clean uninstall with table drops, option cleanup, and cron event removal
- Well-structured single-responsibility classes

### Issues to Address

#### Low Priority

| # | File | Issue | Detail |
|---|------|-------|--------|
| 1 | `src/Encryption/Options_Encryptor.php:83-84` | Same hardcoded encryption fallback issue as Forms plugin | Shares the same pattern; should fail loudly if salts undefined. |
| 2 | `src/REST/SNS_Controller.php` | No rate limiting on SNS webhook endpoint | Consider IP-based rate limiting to prevent abuse, though AWS-side limits exist. |
| 3 | Settings validation | No API key format validation before encryption | Could validate AWS key format during settings save to catch typos early. |

**This plugin has no other actionable issues.** It is production-ready.

---

## Plugin: leastudios-snippets

### What's Done Well
- Secure `eval()` implementation with proper guardrails: only published/active snippets execute, custom error handler catches failures, safe mode auto-deactivates broken snippets
- REST API explicitly disabled for the CPT (`show_in_rest => false`) - correct for code storage
- No direct database queries; uses WordPress post meta and options APIs exclusively
- Proper meta registration with `sanitize_callback` and `auth_callback`
- Good admin JS using strict mode and WordPress APIs
- Full safe mode implementation with admin notices and reactivation workflow

### Issues to Address

#### Medium Priority

| # | File | Issue | Detail |
|---|------|-------|--------|
| 1 | `src/Admin/Snippet_Editor.php:370-371` | `sanitize_text_field()` on conditions JSON | Same issue as Forms plugin. JSON should be decoded and validated structurally, not passed through `sanitize_text_field()` which strips characters. Use the same sanitization callback defined in the meta registration. |
| 2 | `src/Admin/Snippet_Editor.php:364-366` | Priority saved with `sanitize_text_field()` | Use `absint()` for the priority field since it's a numeric value. |
| 3 | `src/Admin/Safe_Mode_Notice.php:111` | Nonce check without explicit `isset()` | Add `isset($_GET['_wpnonce'])` check before `wp_verify_nonce()` for clarity and to avoid passing empty string. |

#### Low Priority

| # | File | Issue | Detail |
|---|------|-------|--------|
| 4 | `src/Admin/Snippet_Editor.php:123,182` | Inline `style="display:none;"` via PHP echo | Use CSS classes (e.g., `.hidden`) instead of inline styles for cleaner separation. |
| 5 | `src/Execution/Snippet_Executor.php:97-100` | Type casting before empty check | Cast after the empty check: `$location = !empty($raw) ? (string) $raw : 'everywhere';` |
| 6 | `src/Admin/Library_Page.php:117` | Query parameter for install feedback | Consider transient-based admin notices instead of `$_GET['installed']` parameter. |

---

## Cross-Plugin Issues

### 1. Shared Options_Encryptor Fallback Pattern
Both `leastudios-forms` and `leastudios-mailer` have the same insecure fallback in their `Options_Encryptor`:
```php
$auth_key = defined( 'AUTH_KEY' ) ? AUTH_KEY : 'default-auth-key';
$salt     = defined( 'SECURE_AUTH_SALT' ) ? SECURE_AUTH_SALT : 'default-salt';
```
**Recommendation:** Replace with an exception or `wp_die()` if salts are undefined. Any WordPress installation without these constants has larger problems, and silently using weak keys is worse than failing.

### 2. JSON Sanitization via `sanitize_text_field()`
Both `leastudios-forms` (Form_Editor) and `leastudios-snippets` (Snippet_Editor) use `sanitize_text_field()` on JSON POST data. This is inappropriate because it strips newlines and certain characters.

**Recommendation:** Use `wp_unslash()` -> `json_decode()` -> validate structure -> `wp_json_encode()` before saving.

### 3. PHPStan Configuration
The `phpstan.neon` config had two deprecated parameters (`checkMissingIterableValueType`, `checkGenericClassInNonGenericObjectType`) and was missing an exclusion for `plugin-check`. These have been fixed during this review.

---

## Recommendations Summary

### Must Fix (Security Impact)
1. Replace hardcoded encryption fallbacks with exceptions (both Forms and Mailer)
2. Add payment amount bounds validation (Forms)
3. Add rate limiting to payment intent endpoint (Forms)

### Should Fix (Standards / Best Practice)
4. Fix JSON sanitization pattern in Forms and Snippets
5. Use `absint()` for numeric inputs in Snippets
6. Add `sanitize_email()` to Reply-To header construction in Forms
7. Add `sanitize_key()` on field names in Forms
8. Add explicit `isset()` before nonce verification in Snippets

### Nice to Have (Polish)
9. Add iterable value type annotations to satisfy PHPStan level 6
10. Replace inline styles with CSS classes in Snippets
11. Consider rate limiting on SNS webhook endpoint in Mailer
12. Use `hash('sha256', ...)` instead of `md5()` in Forms rate limiter

---

## Conclusion

The codebase is well above average for WordPress plugin development. Security fundamentals (escaping, sanitization, nonces, capabilities, prepared statements) are consistently applied. The architecture is clean with proper separation of concerns and modern PHP practices. The issues identified are primarily edge-case hardening and type-annotation completeness rather than structural problems.

**leastudios-mailer** in particular stands out as an exemplary WordPress plugin implementation and could serve as the reference standard for the other two plugins.
