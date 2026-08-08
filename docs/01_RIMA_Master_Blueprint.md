# RIMA Master Blueprint

**Version:** 0.1  
**Status:** Draft

---

# 1. Executive Summary

RIMA is a super app designed specifically for Mauritania.

The platform will bring transportation, food delivery, package delivery, and future digital services into one trusted application.

RIMA is designed around the realities of Mauritania, including:

- Arabic and French support
- GPS-based navigation
- Pins and landmarks instead of relying on formal street addresses
- Multiple verified phone numbers per user
- Flexible identity verification
- Local payment methods
- AI-assisted customer support

The first public version of RIMA will launch in Nouakchott.

Initial services:

- RIMA Go
- RIMA Food
- RIMA Express

Future services may include:

- RIMA Pay
- RIMA Market
- Grocery delivery
- Pharmacy delivery
- Home services
- Bill payments
- Additional local services

---

# 2. Vision

Make everyday life in Mauritania simpler, safer, and faster.

RIMA aims to become the most trusted digital platform in Mauritania by connecting people, businesses, drivers, restaurants, and local services through one application.

---

# 3. Core Product Principles

## 3.1 Built for Mauritania First

RIMA will be designed around local behavior and infrastructure rather than copying another country's app.

## 3.2 Simplicity

The application must remain easy to understand even for first-time users.

## 3.3 Trust

Safety, transparency, identity verification, and reliable service are core priorities.

## 3.4 Speed

Booking, ordering, driver matching, payments, and support should be fast.

## 3.5 One Account, Many Services

A user should not need separate accounts for RIMA Go, RIMA Food, RIMA Express, or future services.

## 3.6 AI Where Useful

AI should reduce friction and improve the customer experience, but users must be able to reach human support when needed.

## 3.7 Security by Design

Security, privacy, access control, and sensitive identity information must be considered from the beginning.

## 3.8 Scalable Architecture

The system should be capable of growing from a Nouakchott launch to nationwide and future regional expansion.

---

# 4. Launch Market

## Phase 1

Nouakchott

## Future Expansion

- Nouadhibou
- Rosso
- Kaédi
- Kiffa
- Atar
- Other Mauritanian cities

Long-term expansion outside Mauritania may be considered only after strong local product-market fit.

---

# 5. Languages

## Launch

- Arabic
- French

## Future Possibilities

- English
- Pulaar
- Soninke
- Wolof

Language selection will be available during onboarding and later from account settings.

---

# 6. Initial RIMA Services

## 6.1 RIMA Go

Standard ride-hailing service.

The first public ride category will be RIMA Go.

Future ride categories may include premium vehicles, larger vehicles, or additional transport services if demand justifies them.

## 6.2 RIMA Food

Restaurant discovery, ordering, payment, delivery, and order tracking.

## 6.3 RIMA Express

Local package and parcel delivery.

## 6.4 Future Services

Possible future modules:

- RIMA Pay
- Marketplace
- Grocery
- Pharmacy
- Home Services
- Bill Payments

---

# 7. Home Experience

RIMA will open to a Super App Home screen rather than opening directly to a map.

Primary greeting:

**How can RIMA help you today?**

The Home screen will provide clear access to:

- RIMA Go
- RIMA Food
- RIMA Express
- Favorites
- Recent activity
- Promotions and useful recommendations

Maps will open when a location-based service requires them.

---

# 8. Main Navigation

The primary bottom navigation will include:

- Home
- Activity
- Favorites
- Profile

Activity will eventually combine:

- Current rides
- Past rides
- Food orders
- Express deliveries
- Future service activity

---

# 9. Customer Registration

## Required

- Verified phone number

## Optional

- Email
- Profile photo

Phone verification will use OTP.

Mauritania will be the default country during launch, but international phone numbers should remain technically possible.

---

# 10. RIMA Identity Architecture

RIMA will not treat a phone number as the permanent identity of a user.

Each account will receive an internal permanent RIMA ID.

Example structure:

RIMA ID
- Verified phone number 1
- Verified phone number 2
- Verified phone number 3
- Optional email
- Optional verified NNI
- Future Houwiyeti verification

This design reflects the fact that many users may maintain multiple mobile numbers across different Mauritanian networks.

Users may add multiple phone numbers after verifying each number using OTP.

One number may be designated as the primary contact number.

---

# 11. NNI Strategy

Mauritania's 10-digit NNI can support identity verification, but it will not be the public RIMA account identifier.

## Customers

NNI will not be required for basic customer registration.

It may later be used for enhanced verification or regulated services.

## Drivers

NNI will be required as part of driver identity verification.

## Merchants

Restaurant owners will not automatically be required to provide personal NNI information.

Merchant verification will primarily focus on the business and authorized representative.

## Security

NNI data must:

- Never be publicly displayed
- Never be used as the visible RIMA ID
- Be strongly protected
- Have restricted administrative access
- Be stored only when required
- Follow applicable privacy and legal requirements

---

# 12. Houwiyeti Strategy

RIMA will launch without depending on Houwiyeti integration.

The identity architecture will remain ready for future integration.

## Level 1 - Launch

Manual verification.

## Level 2 - Future

Optional assisted verification using Houwiyeti if an officially supported mechanism becomes available.

## Level 3 - Future

Automated identity verification if official APIs, permissions, and legal requirements allow it.

RIMA will not build unofficial or unsupported access to government identity systems.

---

# 13. Location and Address Strategy

RIMA will not require traditional street addresses.

Core navigation methods:

- GPS
- Drop a pin
- Landmarks
- Saved places

Examples of saved places:

- Home
- Work
- Family
- Favorite destinations

RIMA may maintain a curated landmark database for important Mauritanian locations.

---

# 14. Smart Pickup

The pickup process will be designed for areas where GPS alone may not identify the final meeting point.

## Step 1

Automatically detect the customer's GPS position.

## Step 2

Allow the customer to:

- Adjust the pin
- Select a nearby landmark
- Choose a saved place

## Step 3

Ask:

**Can the driver easily find you?**

If not, optional assistance may include:

- Voice note
- Short text instructions
- Future photo assistance
- Other local pickup tools

The extra step should appear only when needed so normal bookings remain fast.

---

# 15. Driver Matching

RIMA will use smart driver matching rather than simply broadcasting every ride to all nearby drivers.

Initial matching factors:

- Distance to customer
- Estimated arrival time
- Driver availability
- Driver rating
- Current trip status

Future improvements may include:

- Traffic
- Acceptance rate
- Cancellation rate
- Reliability
- Vehicle type
- Supply balancing
- Driver earnings fairness

---

# 16. Pricing

RIMA Go will use transparent smart pricing.

Initial fare factors:

- Base fare
- Distance
- Estimated travel time

The customer will see an estimated fare before confirming the ride.

There will be no aggressive surge pricing at launch.

Any situation that can cause the final amount to change must be clearly explained.

---

# 17. Driver Verification

Driver verification will launch with manual approval.

Required information may include:

- Verified phone number
- NNI
- Government-issued identification
- Driver's license
- Vehicle registration
- Vehicle photos
- Driver selfie
- Insurance if required by law or RIMA policy

Drivers cannot accept rides until approved.

Future Houwiyeti-based verification may be added when officially supported.

---

# 18. Merchant Verification

Restaurants and merchants will use business-focused verification.

Possible requirements:

- Business name
- Contact phone
- Business location
- Owner or authorized manager
- Business registration documents where applicable
- License information where applicable
- Payout destination
- Manual RIMA approval

The personal NNI of a restaurant owner will not be universally required.

Verification requirements should be proportional to the role and risk.

---

# 19. RIMA Admin Portal

RIMA will have a separate web-based operations and administration portal.

Major modules:

## Driver Management

- Applications
- Document review
- Approvals
- Rejections
- Suspension
- Vehicle management
- Performance
- Payouts

## Merchant Management

- Applications
- Verification
- Menus
- Operating hours
- Performance
- Payouts

## Customer Management

- Accounts
- Complaints
- Support
- Refunds
- Suspensions

## Live Operations

- Active rides
- Active food orders
- Active deliveries
- Drivers online
- Driver status
- Operational incidents

## Finance

- Revenue
- Commissions
- Driver payouts
- Merchant payouts

## Analytics

- Trips
- Orders
- Wait times
- Acceptance rates
- Cancellations
- Revenue
- Peak periods
- Geographic demand

## Security

- Account restrictions
- Verification review
- Fraud investigation
- Access controls

---

# 20. Customer Support

RIMA will use a hybrid AI-first customer support model.

## Level 1

24/7 AI chat assistant.

## Level 2

AI voice assistant as the product matures.

## Level 3

Human support when AI cannot safely or effectively resolve the issue.

## Level 4

Emergency or urgent support channels for serious incidents.

AI should be able to use relevant RIMA context, such as an active trip or order, so customers do not need to repeat information unnecessarily.

Human agents must receive the prior AI conversation when a case is escalated.

---

# 21. Future RIMA Assistant

RIMA may evolve from customer support into an AI-native assistant.

Future examples:

- "Book me a ride to the airport."
- "Where is my driver?"
- "Order dinner."
- "Send a package."
- "Show restaurants near me."

Transactional AI actions must always follow RIMA authorization, confirmation, payment, and safety rules.

---

# 22. Product Decision Log

## PD-001
Super App Home screen instead of opening directly to a map.

**Status:** Approved

## PD-002
Home greeting: "How can RIMA help you today?"

**Status:** Approved

## PD-003
Launch ride service name: RIMA Go.

**Status:** Approved

## PD-004
Navigation will use GPS, pins, and landmarks.

**Status:** Approved

## PD-005
Phone number required; email optional.

**Status:** Approved

## PD-006
Bottom navigation: Home, Activity, Favorites, Profile.

**Status:** Approved

## PD-007
Smart driver matching.

**Status:** Approved

## PD-008
Smart pricing with no aggressive surge pricing at launch.

**Status:** Approved

## PD-009
Smart Pickup assistance.

**Status:** Approved

## PD-010
Three-level driver identity verification architecture, launching with manual approval.

**Status:** Approved

## PD-011
Separate web-based RIMA Admin Portal.

**Status:** Approved

## PD-012
AI-first customer support with human escalation.

**Status:** Approved

## PD-013
One permanent RIMA account with multiple verified phone numbers and an internal RIMA ID.

**Status:** Approved

## PD-014
NNI is role-dependent and protected; required for drivers but not mandatory for basic customers or all merchants.

**Status:** Approved

---

# 23. Development Philosophy

RIMA will be developed as a production product rather than a disposable prototype.

Core engineering expectations:

- Version-controlled source code
- Documented architecture
- Security review
- Automated testing where practical
- Manual end-to-end testing
- Clear release milestones
- Reusable components
- Modular services
- Monitoring and error reporting
- Controlled access to production systems

AI-generated code must be reviewed, tested, and understood before release.

---

# 24. North Star

**Make everyday life in Mauritania simpler, safer, and faster.**

Every major RIMA feature should support that objective.