# Changelog

## Unreleased

### Enhancements

- `Turbopuffer.query/2` now forwards Finch request options (`:receive_timeout`, `:pool_timeout`, `:request_timeout`) so callers can bound per-query latency

## 0.2.0 (2026-02-19)

### Enhancements

- Add `Turbopuffer.list_namespaces/1,2` for enumerating namespaces via `GET /v1/namespaces` with support for `prefix`, `page_size`, and `cursor` pagination (#4)

### Bug fixes

- Fix `include_attributes: :all` causing 422 from the API by normalizing `:all` to `true`. Invalid values now raise `ArgumentError` (#3)

## 0.1.0

- Initial release
