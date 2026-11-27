/**
 * DRAFT LEGAL COPY — NOT REVIEWED BY A LAWYER.
 *
 * Written from what the software actually does: the fields the API stores, the
 * payment flow, the coin rules and the delivery settings. Anything that is a
 * business or legal decision rather than an observable fact is left as a
 * [BRACKETED PLACEHOLDER] for the Valley Express team to fill in, and the live
 * pages show those brackets rather than hiding them.
 *
 * Have these reviewed before launch. The privacy policy in particular is a
 * Play Store listing requirement and must match what the app really collects.
 */

export const LEGAL_UPDATED = '[DATE OF LAST REVIEW]';

export const PRIVACY = {
  intro:
    'This policy explains what Valley Express collects when you use the app or this website, why we hold it, and what you can ask us to do with it. It covers the customer app, the rider app and valleyexpress.com.np.',
  sections: [
    {
      heading: 'Who we are',
      body: [
        'Valley Express is operated by [REGISTERED COMPANY NAME], registered in Nepal under company number [COMPANY NUMBER], at [REGISTERED ADDRESS].',
        'For anything in this policy, contact [PRIVACY CONTACT EMAIL] or write to us at the address above.',
      ],
    },
    {
      heading: 'What we collect',
      list: [
        'Account details: your name, mobile number, email address and password. Passwords are stored only as a hash — we never hold the password itself.',
        'Delivery details: the addresses you save, the map pin you drop, and any landmark note you add to help a rider find you.',
        'Order history: what you ordered, when, what you paid, the delivery fee charged and the Valley Coins earned or spent.',
        'Messages: what you send to our support desk or to a rider through in-app chat.',
        'Rider location: while an order is live, the assigned rider’s position is recorded so the map can show it to you.',
        'Technical data: the device and app version, and server logs of requests made to our API.',
      ],
    },
    {
      heading: 'What we do not collect',
      body: [
        'We do not store card numbers. Digital payments are handled by the payment gateway, which confirms the result to us; we keep only the gateway’s reference and the amount.',
        'We do not sell your data, and we do not share it for advertising.',
      ],
    },
    {
      heading: 'Why we hold it',
      list: [
        'To take, pack, route and deliver your order, and to let you track it.',
        'To run Valley Coins, offers and refunds correctly.',
        'To answer you in support chat and resolve problems with an order.',
        'To keep the service secure, including rate limiting and fraud checks.',
        'To meet tax and accounting obligations under Nepali law.',
      ],
    },
    {
      heading: 'Who else sees it',
      list: [
        'The rider delivering your order sees your name, delivery address, landmark note and phone number, for that order only.',
        'Our payment gateway, [PAYMENT GATEWAY NAME], processes digital payments.',
        'Our SMS provider, [SMS PROVIDER NAME], sends one-time codes.',
        'Map tiles are served by OpenStreetMap contributors through OpenFreeMap.',
        '[ANY OTHER PROCESSOR — ANALYTICS, HOSTING, EMAIL]',
      ],
    },
    {
      heading: 'How long we keep it',
      body: [
        'Order records are kept for [RETENTION PERIOD, e.g. seven years] to meet tax requirements. Chat messages are kept for [CHAT RETENTION PERIOD]. Rider location history for a delivered order is kept for [LOCATION RETENTION PERIOD]. If you close your account we delete or anonymise the rest.',
      ],
    },
    {
      heading: 'Your choices',
      list: [
        'Ask for a copy of what we hold about you.',
        'Ask us to correct anything that is wrong.',
        'Ask us to delete your account and the data that is not required for tax records.',
        'Ask us to stop messaging you about the app launch, at any time.',
      ],
    },
    {
      heading: 'Children',
      body: [
        'Valley Express is not intended for children. Accounts are for people aged [MINIMUM AGE] and over.',
      ],
    },
    {
      heading: 'Changes',
      body: [
        'If this policy changes we will post the new version here and update the date at the top. Material changes will also be announced in the app.',
      ],
    },
  ],
};

export const TERMS = {
  intro:
    'These terms apply when you order from Valley Express through the app or this website. Please read them — placing an order means you accept them.',
  sections: [
    {
      heading: 'Ordering',
      body: [
        'An order is an offer to buy. It is accepted when our operations desk confirms it in the app. Until then we may decline it, for example if an item is out of stock or your address falls outside a delivery zone.',
        'Prices shown in the app include [TAX TREATMENT — VAT INCLUSIVE OR EXCLUSIVE]. We may correct an obvious pricing error before accepting an order.',
      ],
    },
    {
      heading: 'Delivery',
      body: [
        'We deliver within our published zones in Kathmandu, Lalitpur and Bhaktapur. Coverage is confirmed in the app once you drop your pin.',
        'Delivery times shown are estimates, not guarantees. Traffic, weather, festivals and store load all affect them.',
        'Somebody must be available to receive the order at the address given. If nobody is reachable after [NUMBER] attempts to contact you, the order may be returned and [RETURN CHARGE POLICY] applied.',
      ],
    },
    {
      heading: 'Age-restricted items',
      body: [
        'Where an order contains an age-restricted item, you confirm you are 18 or over and agree to show valid physical identification to the rider on delivery. The rider may refuse to hand over the order if identification is not produced.',
        '[CONFIRM: WHETHER ALCOHOL IS SOLD, AND UNDER WHICH LICENCE NUMBER]',
      ],
    },
    {
      heading: 'Payment',
      body: [
        'You may pay cash on delivery or by digital wallet. Digital payments are verified with the gateway before an order is released for packing.',
      ],
    },
    {
      heading: 'Valley Coins',
      body: [
        'Coins are earned on delivered orders at the rate shown in the app, and may be spent against a later basket. They have no cash value, cannot be transferred between accounts, and are reversed if the order they came from is refunded.',
        'We may change the earn rate with notice in the app. Coins already earned are not affected.',
      ],
    },
    {
      heading: 'Your account',
      body: [
        'Keep your password to yourself. You are responsible for orders placed from your account. Tell us at once if you think somebody else has access.',
        'We may suspend an account for abuse of riders or staff, repeated refused deliveries, or fraud.',
      ],
    },
    {
      heading: 'Liability',
      body: [
        'We are responsible for the goods we deliver and for delivering them with reasonable care. We are not liable for losses we could not reasonably have foreseen.',
        'Nothing here limits any right you have under Nepali consumer law.',
        '[LEGAL REVIEW REQUIRED: LIABILITY CAP AND GOVERNING-LAW WORDING]',
      ],
    },
    {
      heading: 'Contacting us',
      body: ['Questions about these terms go to [LEGAL CONTACT EMAIL].'],
    },
  ],
};

export const REFUNDS = {
  intro:
    'What happens when an order is cancelled, something is missing, or a delivery goes wrong. Our aim is simple: you should not pay for what you did not get.',
  sections: [
    {
      heading: 'Cancelling an order',
      body: [
        'You can cancel free of charge until the order is marked as packed in the app. After packing, [POST-PACKING CANCELLATION POLICY].',
        'We may cancel an order ourselves if an item turns out to be unavailable or your address cannot be reached. You are charged nothing in that case.',
      ],
    },
    {
      heading: 'Missing or wrong items',
      body: [
        'Tell us through in-app chat within [REPORTING WINDOW, e.g. 24 hours] of delivery. We will refund the item, send a replacement, or credit Valley Coins — your choice where practical.',
      ],
    },
    {
      heading: 'Damaged, spoiled or melted goods',
      body: [
        'Ice and chilled items are our responsibility until they reach your door. If ice arrives melted or a chilled item arrives warm, report it in chat and we will refund or replace it.',
        'Photographs help, but we will not insist on them for small items.',
      ],
    },
    {
      heading: 'How refunds are paid',
      body: [
        'Cash-on-delivery orders are refunded by [CASH REFUND METHOD — WALLET CREDIT, BANK TRANSFER OR CASH].',
        'Digital payments are refunded to the original wallet. The gateway usually takes [REFUND PROCESSING TIME] to show it on your side.',
        'Any Valley Coins spent on a refunded order are returned to your wallet, and coins earned on it are reversed.',
      ],
    },
    {
      heading: 'Items we cannot refund',
      body: [
        '[LIST ANY EXCLUSIONS — FOR EXAMPLE OPENED CONSUMABLES, UNLESS FAULTY]',
      ],
    },
  ],
};

export const RIDE_WITH_US = {
  intro:
    'We are building our own rider fleet across Kathmandu, Lalitpur and Bhaktapur — not a marketplace of strangers. If you know the Valley’s lanes and can ride them at night, we would like to hear from you.',
  sections: [
    {
      heading: 'What the work is',
      list: [
        'Collect packed orders from our store and deliver them to customers across your area.',
        'Follow the route in the rider app and keep the customer’s map updated automatically.',
        'Handle cash-on-delivery payments and confirm digital ones at the door.',
        'Check identification where an order contains an age-restricted item.',
        'Carry chilled items in the insulated box provided, cold items first.',
      ],
    },
    {
      heading: 'What you need',
      list: [
        'A valid Nepali driving licence for a motorcycle or scooter.',
        'Your own bike or scooter in roadworthy condition, with valid blue book and insurance.',
        'An Android or iPhone that can run the rider app, and a working mobile number.',
        'Good knowledge of at least one part of the Valley — the lanes, not just the main roads.',
        'Aged [MINIMUM RIDER AGE] or over.',
      ],
    },
    {
      heading: 'Hours and pay',
      body: [
        'Shifts run across our opening hours, with the busiest period in the evening. [SHIFT STRUCTURE].',
        'Pay is [PAY STRUCTURE — PER DELIVERY, HOURLY OR BOTH], paid [PAY FREQUENCY]. [FUEL ALLOWANCE POLICY]. [INSURANCE AND EQUIPMENT PROVIDED].',
      ],
    },
    {
      heading: 'How to apply',
      body: [
        'Use the contact form and tell us which area you know best, what you ride, and when you can work. Our operations desk replies within one working day.',
      ],
    },
  ],
};
