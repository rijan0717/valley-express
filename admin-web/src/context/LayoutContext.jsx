import React, { createContext, useContext, useState, useCallback } from 'react';

// Whether the sidebar is showing on a narrow screen.
//
// Every page renders its own Navbar, so passing a toggle down from the shell
// would mean threading the same prop through all of them. The shell owns the
// state and the Navbar reads it from here instead.
const LayoutContext = createContext({
  sidebarOpen: false,
  toggleSidebar: () => {},
  closeSidebar: () => {},
});

export const LayoutProvider = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const toggleSidebar = useCallback(() => setSidebarOpen((open) => !open), []);
  const closeSidebar = useCallback(() => setSidebarOpen(false), []);

  return (
    <LayoutContext.Provider value={{ sidebarOpen, toggleSidebar, closeSidebar }}>
      {children}
    </LayoutContext.Provider>
  );
};

export const useLayout = () => useContext(LayoutContext);

export default LayoutContext;
