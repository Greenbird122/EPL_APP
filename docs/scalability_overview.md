# REPAIR-AI Scalability Overview

## Current Frontend Readiness

REPAIR-AI is presentation-ready and backend-ready from the frontend side. The app already separates patient and CHP journeys, supports English and Kiswahili, includes role-aware routing, and models key care flows: symptom reporting, risk screening results, referrals, report history, follow-up, USSD access, WhatsApp support, and a CHP case queue.

The current frontend uses local/mock providers intentionally while backend APIs are pending. This keeps the experience demonstrable without pretending that production infrastructure is already connected.

## Ready To Scale With Backend APIs

- Patient authentication can connect to phone OTP and patient profile APIs.
- CHP authentication can connect to staff credentials and role claims.
- Patient reports can move from local state into database-backed records.
- Referrals can connect to facility APIs and referral status updates.
- CHP queue data can be replaced by assigned-case APIs.
- USSD and WhatsApp submissions can sync into the same report/referral system.

## Backend Needed Before Production

- Real authentication, token refresh, and server-side role authorization.
- Persistent patient, report, referral, facility, and provider case databases.
- Secure storage for sensitive health data.
- API validation and audit logs for consent, referrals, and clinical actions.
- USSD and WhatsApp sync pipelines.
- Pagination, search, and filtering for provider/CHP queues.

## Production Hardening Needed

- Clinical review and validation of risk-screening logic.
- Privacy controls for export, deletion, consent, and data retention.
- Crash reporting, monitoring, analytics, and release observability.
- Offline sync conflict handling for low-connectivity environments.
- Environment-based configuration for staging and production APIs.
- Security review before handling real patient records.

## Presentation Positioning

Use this wording:

> The frontend is stable, tested, and backend-ready. It demonstrates the complete patient and CHP experience using local/mock providers while backend APIs are pending. Production deployment requires backend auth, secure persistence, clinical validation, privacy controls, and monitoring.
