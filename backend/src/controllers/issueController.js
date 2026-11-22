const Issue = require('../models/Issue');
const Notification = require('../models/Notification');
const { getIO } = require('../sockets');

const generateTicketNo = () => {
  const rand = Math.floor(10000 + Math.random() * 90000);
  return `ISS-${rand}`;
};

// POST /api/issues
// Reporter (Customer or Rider) submits an issue
const createIssue = async (req, res) => {
  try {
    const { title, description, category = 'other', screenshot = null } = req.body;

    const errors = {};
    if (!title || !title.trim() || title.trim().length < 3) {
      errors.title = 'Title must be at least 3 characters long';
    }
    if (!description || !description.trim() || description.trim().length < 10) {
      errors.description = 'Please provide a detailed description (at least 10 characters)';
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed. Please correct the highlighted fields.',
        errors,
      });
    }

    const ticketNo = generateTicketNo();
    const issue = await Issue.create({
      ticketNo,
      reporter: req.user._id,
      reporterRole: req.user.role || 'customer',
      reporterName: req.user.name || 'Anonymous User',
      reporterPhone: req.user.phone || '',
      reporterEmail: req.user.email || '',
      title: title.trim(),
      description: description.trim(),
      category,
      screenshot: screenshot || null,
      status: 'pending',
    });

    // Notify operations admin in real time via socket
    try {
      const io = getIO();
      if (io) {
        io.emit('new_issue', {
          ticketNo: issue.ticketNo,
          title: issue.title,
          reporterName: issue.reporterName,
          reporterRole: issue.reporterRole,
          category: issue.category,
          createdAt: issue.createdAt,
        });
      }
    } catch (sockErr) {
      console.warn('Socket emit error for new_issue:', sockErr.message);
    }

    res.status(201).json({
      success: true,
      message: 'Issue raised successfully. Our support & dispatch team is reviewing your report.',
      issue,
    });
  } catch (error) {
    console.error('Create issue error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error raising issue' });
  }
};

// GET /api/issues/my
// Get issues submitted by currently logged-in customer or rider
const getMyIssues = async (req, res) => {
  try {
    const issues = await Issue.find({
      reporter: req.user._id,
      isDeleted: { $ne: true },
    }).sort({ createdAt: -1 });

    res.json({
      success: true,
      count: issues.length,
      issues,
    });
  } catch (error) {
    console.error('Get my issues error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error fetching issues' });
  }
};

// GET /api/issues or /api/admin/issues (Admin only)
const getAllIssues = async (req, res) => {
  try {
    const { status, role, search } = req.query;
    const query = { isDeleted: { $ne: true } };

    if (status && status !== 'all') {
      query.status = status;
    }
    if (role && role !== 'all') {
      query.reporterRole = role;
    }
    if (search && search.trim()) {
      const regex = new RegExp(search.trim(), 'i');
      query.$or = [
        { ticketNo: regex },
        { title: regex },
        { description: regex },
        { reporterName: regex },
        { reporterPhone: regex },
      ];
    }

    const issues = await Issue.find(query)
      .populate('reporter', 'name phone email role')
      .populate('resolvedBy', 'name email')
      .sort({ createdAt: -1 });

    // Aggregate status counts for quick tab filters
    const stats = {
      all: await Issue.countDocuments({ isDeleted: { $ne: true } }),
      pending: await Issue.countDocuments({ isDeleted: { $ne: true }, status: 'pending' }),
      investigating: await Issue.countDocuments({ isDeleted: { $ne: true }, status: 'investigating' }),
      resolved: await Issue.countDocuments({ isDeleted: { $ne: true }, status: 'resolved' }),
      rejected: await Issue.countDocuments({ isDeleted: { $ne: true }, status: 'rejected' }),
      customerCount: await Issue.countDocuments({ isDeleted: { $ne: true }, reporterRole: 'customer' }),
      riderCount: await Issue.countDocuments({ isDeleted: { $ne: true }, reporterRole: 'rider' }),
    };

    res.json({
      success: true,
      count: issues.length,
      stats,
      issues,
    });
  } catch (error) {
    console.error('Get all issues error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error fetching all issues' });
  }
};

// PATCH /api/issues/:id/status (Admin only)
// Admin updates status (investigating, resolved, rejected, pending) and adds an explanation note
const updateIssueStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminNote = '' } = req.body;

    if (!['pending', 'investigating', 'resolved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value' });
    }

    const issue = await Issue.findOne({ _id: id, isDeleted: { $ne: true } });
    if (!issue) {
      return res.status(404).json({ success: false, message: 'Issue not found' });
    }

    issue.status = status;
    if (adminNote !== undefined) {
      issue.adminNote = adminNote.trim();
    }

    if (status === 'resolved' || status === 'rejected') {
      issue.resolvedAt = new Date();
      issue.resolvedBy = req.user._id;
    } else {
      issue.resolvedAt = null;
      issue.resolvedBy = null;
    }

    await issue.save();

    // Send notification to the user/rider who reported this issue
    try {
      const statusLabels = {
        pending: 'Pending Review',
        investigating: 'Under Investigation',
        resolved: 'Resolved',
        rejected: 'Closed / Not Actionable',
      };

      const noteText = issue.adminNote
        ? `\nAction Taken: "${issue.adminNote}"`
        : '';

      await Notification.create({
        user: issue.reporter,
        title: `Issue #${issue.ticketNo} Update: ${statusLabels[status]}`,
        body: `Your reported issue "${issue.title}" status is now ${statusLabels[status]}.${noteText}`,
        type: 'issue_update',
        data: {
          issueId: issue._id,
          ticketNo: issue.ticketNo,
          meta: { status, adminNote: issue.adminNote },
        },
      });

      const io = getIO();
      if (io) {
        io.emit('issue_updated', {
          issueId: issue._id,
          ticketNo: issue.ticketNo,
          status: issue.status,
          adminNote: issue.adminNote,
          reporterId: issue.reporter,
        });
      }
    } catch (notifErr) {
      console.warn('Failed to dispatch notification for issue status update:', notifErr.message);
    }

    res.json({
      success: true,
      message: `Issue #${issue.ticketNo} status updated to ${status}`,
      issue,
    });
  } catch (error) {
    console.error('Update issue status error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error updating issue' });
  }
};

// DELETE /api/issues/:id (Admin only)
// Explicit requirement: "added issue is only removed if admin delete it"
const deleteIssue = async (req, res) => {
  try {
    const { id } = req.params;
    const issue = await Issue.findById(id);

    if (!issue) {
      return res.status(404).json({ success: false, message: 'Issue not found' });
    }

    // Mark as deleted so it is removed from customer, rider, and admin lists
    issue.isDeleted = true;
    await issue.save();

    res.json({
      success: true,
      message: `Issue #${issue.ticketNo} deleted permanently by admin`,
    });
  } catch (error) {
    console.error('Delete issue error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error deleting issue' });
  }
};

module.exports = {
  createIssue,
  getMyIssues,
  getAllIssues,
  updateIssueStatus,
  deleteIssue,
};
