/**
 * Single source of truth for the public website's copy.
 *
 * Operational figures below mirror the defaults in backend/src/models/Setting.js
 * (delivery fee, free-delivery threshold, service hours). If an admin changes
 * them in Store Settings, update them here too — nothing on the marketing site
 * reads the live settings document.
 */

export const BRAND = {
  name: 'Valley Express',
  tagline: 'Fast to order. Fast to your door.',
  shortPitch:
    'On-demand delivery of snacks, soft drinks, ice, mixers and daily essentials across Kathmandu Valley.',
  cities: ['Kathmandu', 'Lalitpur', 'Bhaktapur'],
  hours: { open: '10:00', close: '23:30' },
  deliveryFee: 100,
  freeDeliveryThreshold: 1500,
  coinsPerRupees: 10,
  // TODO: replace with the real support channels before launch.
  email: 'hello@valleyexpress.com.np',
  phone: '+977 9800000000',
  address: 'Kathmandu, Bagmati Province, Nepal',
  social: {
    facebook: 'https://facebook.com/',
    instagram: 'https://instagram.com/',
    tiktok: 'https://tiktok.com/',
  },
};

export const CATEGORIES = [
  { name: 'Snacks', note: 'Crisps, instant noodles, biscuits, chocolate' },
  { name: 'Soft drinks', note: 'Colas, energy drinks, juice, bottled water' },
  { name: 'Ice', note: 'Cubed and crushed, delivered still frozen' },
  { name: 'Mixers', note: 'Tonic, soda, ginger ale, fresh lime' },
  { name: 'Essentials', note: 'Eggs, milk, bread, batteries, lighters' },
];

export const FEATURES = [
  {
    title: 'Watch your rider move',
    body:
      'Every order opens a live map. You see the rider leave the store, turn onto your street and reach your gate — no guessing, no "where is my order" phone calls.',
    icon: 'map',
  },
  {
    title: 'Valley Coins on every order',
    body:
      'Earn one Valley Coin for every Rs 10 you spend. Coins stack up quietly and come straight off your next basket at checkout.',
    icon: 'coin',
  },
  {
    title: 'Talk to a person',
    body:
      'In-app chat connects you to the Valley Express support desk and to your rider while the order is live. Messages, not hold music.',
    icon: 'chat',
  },
  {
    title: 'Ice that is still ice',
    body:
      'Cold items ride in insulated boxes and go out on the shortest route first, so ice arrives frozen and drinks arrive cold.',
    icon: 'snow',
  },
  {
    title: 'Pay the way you already pay',
    body:
      'Cash on delivery, or digital wallet at checkout. Every digital payment is verified against the gateway before the order is released.',
    icon: 'wallet',
  },
  {
    title: 'Built for the Valley',
    body:
      'Routing, delivery zones and rider shifts are tuned for Kathmandu, Lalitpur and Bhaktapur traffic — not borrowed from a city with wider roads.',
    icon: 'pin',
  },
];

export const STEPS = [
  {
    title: 'Pick your basket',
    body: 'Browse by category, search for what you want, and save the drinks you order most for one-tap reordering.',
  },
  {
    title: 'Confirm and pay',
    body: 'Set your delivery pin on the map, apply coins or an offer, then pay by cash on delivery or digital wallet.',
  },
  {
    title: 'Track to your door',
    body: 'A rider accepts within moments. Follow the route live and message them if your gate is hard to find.',
  },
];

export const FAQS = [
  {
    q: 'Which areas do you deliver to?',
    a: 'Valley Express covers Kathmandu, Lalitpur and Bhaktapur. Delivery zones are set by our operations team, so the app confirms coverage once you drop your pin.',
  },
  {
    q: 'What are your delivery hours?',
    a: `The store takes orders from ${BRAND.hours.open} to ${BRAND.hours.close} every day. Hours can shift during festivals and public holidays — the app always shows the live store status.`,
  },
  {
    q: 'How much is delivery?',
    a: `Delivery starts at Rs ${BRAND.deliveryFee}, with a surge applied on longer distances. Baskets over Rs ${BRAND.freeDeliveryThreshold.toLocaleString('en-NP')} are delivered free.`,
  },
  {
    q: 'How do Valley Coins work?',
    a: `You earn one coin for every Rs ${BRAND.coinsPerRupees} spent on a delivered order. Coins appear in your wallet automatically and can be spent at checkout on a later order.`,
  },
  {
    q: 'Do you deliver alcohol?',
    a: 'No. Valley Express delivers mixers, soft drinks and ice only. We will not carry alcohol until a liquor licence is issued, and the category stays switched off in the app until then.',
  },
  {
    q: 'Is the app available now?',
    a: 'The Android and iOS apps are in final testing. Join the notify list on this page and we will message you the day they go live on the stores.',
  },
];
