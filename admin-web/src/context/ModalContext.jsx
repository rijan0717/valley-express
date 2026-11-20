import React, { createContext, useContext, useState, useRef, useEffect } from 'react';

const ModalContext = createContext();

export const ModalProvider = ({ children }) => {
  const [modalState, setModalState] = useState({
    isOpen: false,
    title: '',
    message: '',
    type: 'info', // 'info' | 'success' | 'warning' | 'danger'
    isConfirm: false,
    isPrompt: false,
    promptValue: '',
    promptPlaceholder: '',
    confirmText: 'OK',
    cancelText: 'Cancel',
  });

  const [toasts, setToasts] = useState([]);
  const resolveRef = useRef(null);
  const promptInputRef = useRef(null);

  // Auto focus input when prompt dialog appears
  useEffect(() => {
    if (modalState.isOpen && modalState.isPrompt) {
      setTimeout(() => {
        promptInputRef.current?.focus();
        promptInputRef.current?.select();
      }, 50);
    }
  }, [modalState.isOpen, modalState.isPrompt]);

  const showAlert = (message, title = 'Notification', type = 'info') => {
    return new Promise((resolve) => {
      resolveRef.current = resolve;
      setModalState({
        isOpen: true,
        title,
        message: String(message || ''),
        type,
        isConfirm: false,
        isPrompt: false,
        confirmText: 'Acknowledge',
        cancelText: '',
      });
    });
  };

  const showConfirm = (message, title = 'Confirmation Required', isDanger = false, confirmText = 'Confirm', cancelText = 'Cancel') => {
    return new Promise((resolve) => {
      resolveRef.current = resolve;
      setModalState({
        isOpen: true,
        title,
        message: String(message || ''),
        type: isDanger ? 'danger' : 'warning',
        isConfirm: true,
        isPrompt: false,
        confirmText,
        cancelText,
      });
    });
  };

  const showPrompt = (message, defaultValue = '', title = 'Action Required', placeholder = 'Enter details...') => {
    return new Promise((resolve) => {
      resolveRef.current = resolve;
      setModalState({
        isOpen: true,
        title,
        message: String(message || ''),
        type: 'info',
        isConfirm: true,
        isPrompt: true,
        promptValue: defaultValue,
        promptPlaceholder: placeholder,
        confirmText: 'Submit',
        cancelText: 'Cancel',
      });
    });
  };

  const showToast = (message, type = 'success', duration = 3500) => {
    const id = Date.now() + Math.random();
    setToasts((prev) => [...prev, { id, message: String(message || ''), type }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, duration);
  };

  const handleConfirm = () => {
    const val = modalState.isPrompt ? modalState.promptValue : true;
    setModalState((prev) => ({ ...prev, isOpen: false }));
    if (resolveRef.current) {
      resolveRef.current(val);
      resolveRef.current = null;
    }
  };

  const handleCancel = () => {
    setModalState((prev) => ({ ...prev, isOpen: false }));
    if (resolveRef.current) {
      resolveRef.current(modalState.isPrompt ? null : false);
      resolveRef.current = null;
    }
  };

  return (
    <ModalContext.Provider
      value={{
        showAlert,
        showConfirm,
        showPrompt,
        showToast,
      }}
    >
      {children}

      {/* CENTERED POPUP DIALOG (Always Dead Center of Screen) */}
      {modalState.isOpen && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(31, 42, 68, 0.65)',
            backdropFilter: 'blur(3px)',
            WebkitBackdropFilter: 'blur(3px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 999999,
            padding: '20px',
          }}
          onClick={(e) => {
            if (e.target === e.currentTarget && !modalState.isPrompt) {
              handleCancel();
            }
          }}
        >
          <div
            style={{
              backgroundColor: '#FFFFFF',
              borderRadius: '8px',
              border: `2px solid ${modalState.type === 'danger' ? '#DC2626' : '#003893'}`,
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.35)',
              width: '100%',
              maxWidth: '440px',
              overflow: 'hidden',
              animation: 'modalScaleIn 0.18s cubic-bezier(0.16, 1, 0.3, 1)',
              display: 'flex',
              flexDirection: 'column',
            }}
          >
            {/* Header */}
            <div
              style={{
                padding: '16px 20px',
                borderBottom: '1px solid #D1D5DB',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                backgroundColor: modalState.type === 'danger' ? '#FEF2F2' : '#F8FAFC',
              }}
            >
              <div
                style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor:
                    modalState.type === 'danger'
                      ? '#FEE2E2'
                      : modalState.type === 'success'
                      ? '#DCFCE7'
                      : '#E0E7FF',
                  color:
                    modalState.type === 'danger'
                      ? '#DC2626'
                      : modalState.type === 'success'
                      ? '#16A34A'
                      : '#003893',
                  fontSize: '16px',
                  fontWeight: 'bold',
                }}
              >
                {modalState.type === 'danger' ? '!' : modalState.type === 'success' ? '✔' : 'ℹ'}
              </div>
              <h3
                style={{
                  margin: 0,
                  fontSize: '15px',
                  fontWeight: 700,
                  color: modalState.type === 'danger' ? '#DC2626' : '#003893',
                  fontFamily: 'Poppins, sans-serif',
                }}
              >
                {modalState.title}
              </h3>
            </div>

            {/* Content Body */}
            <div style={{ padding: '20px', fontSize: '13px', color: '#1F2A44', lineHeight: 1.5 }}>
              <div style={{ whiteSpace: 'pre-wrap', marginBottom: modalState.isPrompt ? '14px' : '0' }}>
                {modalState.message}
              </div>

              {modalState.isPrompt && (
                <input
                  ref={promptInputRef}
                  type="text"
                  value={modalState.promptValue}
                  onChange={(e) =>
                    setModalState((prev) => ({ ...prev, promptValue: e.target.value }))
                  }
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') handleConfirm();
                    if (e.key === 'Escape') handleCancel();
                  }}
                  placeholder={modalState.promptPlaceholder}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: '1.5px solid #003893',
                    borderRadius: '4px',
                    fontSize: '13px',
                    outline: 'none',
                    boxSizing: 'border-box',
                  }}
                />
              )}
            </div>

            {/* Footer Action Buttons */}
            <div
              style={{
                padding: '12px 20px',
                borderTop: '1px solid #E2E8F0',
                backgroundColor: '#F8FAFC',
                display: 'flex',
                justifyContent: 'flex-end',
                gap: '10px',
              }}
            >
              {(modalState.isConfirm || modalState.isPrompt) && (
                <button
                  type="button"
                  onClick={handleCancel}
                  className="btn btn-secondary btn-sm"
                  style={{ minWidth: '85px', minHeight: '36px', fontSize: '12px' }}
                >
                  {modalState.cancelText}
                </button>
              )}
              <button
                type="button"
                onClick={handleConfirm}
                className="btn btn-primary btn-sm"
                style={{
                  minWidth: '95px',
                  minHeight: '36px',
                  fontSize: '12px',
                  backgroundColor: modalState.type === 'danger' ? '#DC2626' : '#FF6B1A',
                  borderColor: modalState.type === 'danger' ? '#DC2626' : '#FF6B1A',
                }}
              >
                {modalState.confirmText}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FLOATING TOAST NOTIFICATIONS (Top Center) */}
      {toasts.length > 0 && (
        <div
          style={{
            position: 'fixed',
            top: '24px',
            left: '50%',
            transform: 'translateX(-50%)',
            zIndex: 9999999,
            display: 'flex',
            flexDirection: 'column',
            gap: '8px',
            pointerEvents: 'none',
          }}
        >
          {toasts.map((t) => (
            <div
              key={t.id}
              style={{
                pointerEvents: 'auto',
                backgroundColor: t.type === 'error' ? '#DC2626' : t.type === 'success' ? '#003893' : '#1F2A44',
                color: '#FFFFFF',
                padding: '10px 18px',
                borderRadius: '6px',
                boxShadow: '0 10px 25px rgba(0,0,0,0.2)',
                fontSize: '12px',
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                letterSpacing: '0.3px',
                border: '1px solid rgba(255,255,255,0.2)',
              }}
            >
              <span>{t.type === 'error' ? '⚠' : t.type === 'success' ? '✔' : 'ℹ'}</span>
              <span>{t.message}</span>
            </div>
          ))}
        </div>
      )}
    </ModalContext.Provider>
  );
};

export const useModal = () => {
  const context = useContext(ModalContext);
  if (!context) {
    throw new Error('useModal must be used within a ModalProvider');
  }
  return context;
};
