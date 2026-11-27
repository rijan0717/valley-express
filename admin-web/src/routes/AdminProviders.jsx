import React from 'react';
import { SocketProvider } from '../context/SocketContext';
import { ModalProvider } from '../context/ModalContext';
import { ChatUnreadProvider } from '../context/ChatUnreadContext';
import { LayoutProvider } from '../context/LayoutContext';

/**
 * The dashboard's context stack, in one lazily-loaded module.
 *
 * Importing the providers from App.jsx would pull socket.io-client into the
 * chunk the public site loads, so they are gathered here and the whole file is
 * loaded on demand with the rest of the dashboard.
 */
const AdminProviders = ({ children }) => (
  <SocketProvider>
    <ModalProvider>
      <ChatUnreadProvider>
        <LayoutProvider>{children}</LayoutProvider>
      </ChatUnreadProvider>
    </ModalProvider>
  </SocketProvider>
);

export default AdminProviders;
