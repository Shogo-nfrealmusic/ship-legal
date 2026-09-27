# Recipe: testimonials, reviews and marketing claims (FTC)

Goal: every testimonial is from a real customer with a real experience, material
connections are disclosed, and numeric/performance claims are true and substantiated.

## Done when
- Hard-coded testimonials/reviews/star ratings are either (a) wrapped with
  `TODO(legal-check): confirm this is a real customer quote and you have permission` and
  listed in Human TODO, or (b) removed if they are obviously placeholders (Lorem, "John
  Doe", AI-written, or generated). Never invent new ones.
- Specific claims ("Trusted by 50,000+", "#1", "guaranteed results", "lose 12 kg",
  "used by engineers at Google") get a `TODO(legal-check): substantiate` marker and a
  Human TODO; remove "guaranteed" unless there is an actual guarantee with terms.
  Third-party brand names in claims ("used at Google") need proof and ideally permission.
- If reviewers got something (free product, payment, affiliate), a disclosure sits next
  to the testimonial.

## Stack notes
Copy-only change in any stack. Keep layout; replace text or add a small note under it.
