/**
 * PLACEHOLDER CONTENT — replace before launch.
 *
 * Sample posts written to exercise the blog layout, typography and animations.
 * The operational details in them follow the real product, but the posts were
 * not written by the Valley Express team and carry no real publication dates.
 * Swap `POSTS` for genuine editorial copy (or move it behind the API) before
 * this site goes live.
 */
export const POSTS = [
  {
    slug: 'what-quick-delivery-means-in-kathmandu',
    title: 'What quick delivery actually means in Kathmandu',
    excerpt:
      'Thirty minutes in a city of wide roads and grid blocks is not thirty minutes in the Valley. Here is how we think about speed.',
    date: '2026-10-14',
    readingMinutes: 5,
    tag: 'Operations',
    body: [
      'Quick-delivery promises are usually written for cities with wide roads, numbered blocks and addresses that a map can find on the first try. Kathmandu is not that city, and pretending otherwise is how delivery services end up with riders circling a tole looking for a gate.',
      'We build around three facts instead. Lanes narrow without warning, so a scooter beats a car on nearly every route. Addresses are landmarks rather than numbers, so a dropped map pin and a short chat with the rider beat a street name. And traffic is directional — the ring road at six in the evening is not the ring road at eleven at night.',
      'So our routing works outward from the store in travel time rather than straight-line distance, and our delivery fee follows the same logic: a basket two kilometres away through Chabahil at rush hour is a different job from the same basket at midday.',
      'The honest version of a speed promise is this: we show you the rider on a live map from the moment they accept, and we tell you when the store is busy. You get the real picture rather than a countdown that resets.',
    ],
  },
  {
    slug: 'how-valley-coins-work',
    title: 'How Valley Coins work, in plain numbers',
    excerpt:
      'One coin for every Rs 10 you spend, straight off a later basket. No tiers, no expiry games, no points maths.',
    date: '2026-09-28',
    readingMinutes: 4,
    tag: 'Product',
    body: [
      'Loyalty schemes usually fail for one reason: nobody can work out what the points are worth. We wanted a number you can hold in your head, so Valley Coins run on a single rule — you earn one coin for every Rs 10 you spend on a delivered order.',
      'Coins land in your wallet when the order is marked delivered, not when it is placed, so a cancelled basket never leaves phantom coins behind. If an order is refunded, the coins come back out again, which is the part most schemes quietly skip.',
      'At checkout you choose how many coins to spend. They come off the basket total before delivery is added, and whatever you do not spend simply stays in the wallet for next time.',
      'That is the whole scheme. There are no tiers to climb, no bonus multipliers that appear and vanish, and no expiry clock running in the background.',
    ],
  },
  {
    slug: 'why-ice-is-the-hardest-thing-we-deliver',
    title: 'Why ice is the hardest thing we deliver',
    excerpt:
      'A bag of ice is a delivery with a timer attached. It changed how we pack, how we route and what we promise.',
    date: '2026-09-05',
    readingMinutes: 6,
    tag: 'Behind the scenes',
    body: [
      'Most items in a basket do not care how long the journey takes. Ice cares a great deal. It is the only thing we carry that is actively getting worse from the moment it leaves the freezer, and it sets the standard for everything else.',
      'Packing came first. Ice and chilled drinks travel in insulated boxes rather than loose in the delivery bag, and they are the last thing loaded so they are the first thing out.',
      'Routing came second. An order containing ice is not batched behind two dry orders going the other way, even when batching would be more efficient on paper. The efficiency is not worth handing someone a bag of cold water.',
      'The third change was to what we say. We do not claim ice arrives in perfect condition on a forty-minute run across the Valley in May. We tell you the realistic window, and we let you watch the rider cover it.',
    ],
  },
  {
    slug: 'building-for-riders-not-just-customers',
    title: 'Building for riders, not just customers',
    excerpt:
      'Half of our app is used by someone wearing a helmet. That changes how the screens are designed.',
    date: '2026-08-19',
    readingMinutes: 5,
    tag: 'Engineering',
    body: [
      'A delivery platform has two sets of users and only one of them is sitting comfortably. The customer taps through a basket on a sofa. The rider reads the same app at a junction, one-handed, in the sun, possibly in the rain, wearing gloves.',
      'So the rider screens are built to different rules. Targets are larger, the critical action on each screen is the biggest thing on it, and status changes take one tap with no confirmation dialogue to dismiss.',
      'Contrast matters more than polish. Pale grey text on white is unreadable through a visor at midday, so rider-facing type is heavier and darker than the dashboard equivalent.',
      'And anything that can wait, waits. Earnings summaries, history and settings sit behind the live order rather than beside it, because nothing should compete for attention with the job in hand.',
    ],
  },
];

export const getPost = (slug) => POSTS.find((post) => post.slug === slug);
