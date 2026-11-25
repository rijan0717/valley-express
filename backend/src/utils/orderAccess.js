// Who is allowed to see or act on a given order.
//
// Orders carry a customer's delivery address and phone number, so they must
// never be readable by an arbitrary signed-in account. Access is limited to
// the three parties with a legitimate interest: the customer who placed it,
// the rider assigned to deliver it, and operations (admin).

// Compare an ObjectId-or-populated-doc against a user id without caring which
// shape it arrived in.
const sameId = (a, b) => {
  if (!a || !b) return false;
  const av = a._id ? a._id.toString() : a.toString();
  const bv = b._id ? b._id.toString() : b.toString();
  return av === bv;
};

const isAdmin = (user) => user && user.role === 'admin';

// The rider currently assigned to this order.
const isAssignedRider = (order, user) =>
  user && user.role === 'rider' && order.rider && sameId(order.rider, user._id);

// The customer who owns this order.
const isOrderOwner = (order, user) =>
  user && order.customer && sameId(order.customer, user._id);

// Read access: owner, assigned rider, or admin.
const canViewOrder = (order, user) =>
  isAdmin(user) || isOrderOwner(order, user) || isAssignedRider(order, user);

module.exports = { sameId, isAdmin, isAssignedRider, isOrderOwner, canViewOrder };
