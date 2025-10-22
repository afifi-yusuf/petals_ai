# Petals AI

**The Private AI Revolution in Health & Wellness**

> **Petals AI is your personal, privacy-first wellness companion. Powered by Apple on-device AI, Petals helps you blossom with completely private guidance, nutrition, workouts, journaling, and detox tools—never sending your data to the cloud.**

---

## Features

- **On-Device Apple Intelligence**
  - Utilizes Apple’s Foundation Models in iOS 26, macOS 26, and visionOS 26.
  - No user data ever leaves your device—privacy is always the default.

- **Personalized AI Coach**
  - Context-aware workout, nutrition, and mindfulness plans.
  - Guided meditation and intelligent journaling tailored to your current mood and health.

- **HealthKit Integration**
  - Reads Apple Health signals (sleep, activity, energy, etc.) to deliver fully adaptive recommendations.

- **Digital Detox Tools**
  - Block distractions and reclaim your focus instantly.
  - Build a healthier relationship with technology.

- **No Data Collection**
  - The app collects no data; see [privacy policy](#privacy-policy) for more.

---

## How It Works

Petals leverages Apple’s FoundationModels framework with on-device 3B parameter LLMs to deliver private, structured intelligence:

import FoundationModels

let session = LanguageModelSession()
let prompt = Prompt(text: "Generate a light workout plan for someone with low energy.")
let response = try await session.respond(to: prompt, generating: WorkoutPlan.self)


With guided generation (`@Generable`, `@Guide`), Petals produces reliable, strongly-typed Swift structs—never brittle text, always private.

---

## Installation

Petals is available for:

- **iPhone** (requires iPhone 15 Pro or later, iOS 26+)
- **Mac** (requires Apple Silicon, macOS 26+)
- **Apple Vision** (visionOS 26+)

Get it from the [App Store](https://apps.apple.com/us/app/petals-ai/id6749387193) or [TestFlight](https://petalsapp.ai).

---

## Privacy Policy

**Petals AI does not collect any data from users.**  
Your health, journaling, and AI conversations are never sent to external servers or shared with third parties.

---

## License

© 2025 Yusuf Afifi. All rights reserved.

---

## Links

- [Petals AI on App Store](https://apps.apple.com/us/app/petals-ai/id6749387193)
- [Petals AI: The Private AI Revolution (Medium)](https://medium.com/@yusuf.afifi/petals-ai-the-private-ai-revolution-e45ea6f3155f)
- [Official Website](https://petalsapp.ai)
```
