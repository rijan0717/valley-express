import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api/client';
import { useModal } from '../context/ModalContext';
import ValleyLoader from '../components/ValleyLoader';

const Products = ({ onReplaySplash }) => {
  const { showAlert, showConfirm, showToast } = useModal();
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);

  // Product Modal State
  const [showProductModal, setShowProductModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [dragActive, setDragActive] = useState(false);
  const [urlInput, setUrlInput] = useState('');
  const [productForm, setProductForm] = useState({
    name: '',
    nameNe: '',
    description: '',
    category: '',
    price: '',
    discountPrice: '',
    stock: 50,
    unit: 'item',
    isAlcohol: false,
    alcoholPercentage: '',
    images: [],
    mainImageIndex: 0,
  });

  // Category Modal State (Full Category CRUD)
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [categoryForm, setCategoryForm] = useState({
    name: '',
    nameNe: '',
    slug: '',
    icon: '',
    isRestricted: false,
  });

  const fetchData = async () => {
    try {
      const [pRes, cRes] = await Promise.all([
        api.get('/products?activeOnly=false'),
        api.get('/categories?activeOnly=false'),
      ]);
      if (pRes.data.success) setProducts(pRes.data.products);
      if (cRes.data.success) setCategories(cRes.data.categories);
    } catch (e) {
      console.error('Error fetching catalog data:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Product Handlers
  const openAddProductModal = () => {
    setEditingProduct(null);
    setUrlInput('');
    setProductForm({
      name: '',
      nameNe: '',
      description: '',
      category: categories[0]?._id || '',
      price: '',
      discountPrice: '',
      stock: 50,
      unit: 'item',
      isAlcohol: false,
      alcoholPercentage: '',
      images: [],
      mainImageIndex: 0,
    });
    setShowProductModal(true);
  };

  const openEditProductModal = (p) => {
    setEditingProduct(p);
    setUrlInput('');
    const existingImages = Array.isArray(p.images)
      ? [...p.images]
      : p.images
      ? [p.images]
      : [];
    setProductForm({
      name: p.name,
      nameNe: p.nameNe || '',
      description: p.description || '',
      category: p.category?._id || p.category || '',
      price: p.price,
      discountPrice: p.discountPrice || '',
      stock: p.stock,
      unit: p.unit || 'item',
      isAlcohol: p.isAlcohol || false,
      alcoholPercentage: p.alcoholPercentage || '',
      images: existingImages,
      mainImageIndex: 0,
    });
    setShowProductModal(true);
  };

  const handleImageFiles = (files) => {
    if (!files || files.length === 0) return;
    const validFiles = Array.from(files).filter((file) => file.type.startsWith('image/'));
    if (validFiles.length === 0) {
      showAlert('Please select valid image files (PNG, JPG, WEBP, SVG) to upload.', 'Invalid File Type', 'warning');
      return;
    }

    let loadedCount = 0;
    const newImages = [];

    validFiles.forEach((file) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        newImages.push(e.target.result);
        loadedCount += 1;
        if (loadedCount === validFiles.length) {
          setProductForm((prev) => ({
            ...prev,
            images: [...prev.images, ...newImages],
          }));
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const handleAddUrlImage = () => {
    const trimmed = urlInput.trim();
    if (!trimmed) return;
    setProductForm((prev) => ({
      ...prev,
      images: [...prev.images, trimmed],
    }));
    setUrlInput('');
  };

  const handleSetMainImage = (index) => {
    setProductForm((prev) => ({
      ...prev,
      mainImageIndex: index,
    }));
  };

  const handleRemoveImage = (index) => {
    setProductForm((prev) => {
      const nextImages = prev.images.filter((_, i) => i !== index);
      let nextMain = prev.mainImageIndex;
      if (nextMain >= nextImages.length) {
        nextMain = Math.max(0, nextImages.length - 1);
      }
      return {
        ...prev,
        images: nextImages,
        mainImageIndex: nextMain,
      };
    });
  };

  const handleSaveProduct = async (e) => {
    e.preventDefault();
    try {
      // Ensure the selected main image is at index 0 for all views and cards
      let finalImages = [...productForm.images];
      if (productForm.mainImageIndex > 0 && productForm.mainImageIndex < finalImages.length) {
        const [selectedMain] = finalImages.splice(productForm.mainImageIndex, 1);
        finalImages.unshift(selectedMain);
      }

      const payload = {
        ...productForm,
        price: Number(productForm.price),
        discountPrice: productForm.discountPrice ? Number(productForm.discountPrice) : undefined,
        stock: Number(productForm.stock),
        alcoholPercentage: productForm.isAlcohol ? Number(productForm.alcoholPercentage) : 0,
        images: finalImages,
      };

      if (editingProduct) {
        const res = await api.put(`/products/${editingProduct._id}`, payload);
        if (res.data.success) {
          setProducts(products.map((p) => (p._id === editingProduct._id ? res.data.product : p)));
          setShowProductModal(false);
        }
      } else {
        const res = await api.post('/products', payload);
        if (res.data.success) {
          setProducts([res.data.product, ...products]);
          setShowProductModal(false);
          showToast(`Product "${res.data.product.name}" created`, 'success');
        }
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Product Save Error', 'danger');
    }
  };

  const handleDeleteProduct = async (id, name) => {
    const confirmed = await showConfirm(
      `Confirm removal of "${name}" from MongoDB catalog? This product will be deleted permanently.`,
      'Delete Product',
      true,
      'Permanently Delete',
      'Cancel'
    );
    if (!confirmed) return;
    try {
      const res = await api.delete(`/products/${id}`);
      if (res.data.success) {
        setProducts(products.filter((p) => p._id !== id));
        showToast(`Product "${name}" deleted`, 'success');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete Product Failed', 'danger');
    }
  };

  const adjustStock = async (product, delta) => {
    const newStock = Math.max(0, product.stock + delta);
    try {
      const res = await api.put(`/products/${product._id}`, { stock: newStock });
      if (res.data.success) {
        setProducts(products.map((p) => (p._id === product._id ? res.data.product : p)));
        showToast(`Stock updated: ${product.name} (${newStock})`, 'info');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Stock Adjustment Failed', 'danger');
    }
  };

  // Category Handlers (Full CRUD)
  const openCategoryManager = () => {
    setEditingCategory(null);
    setCategoryForm({ name: '', nameNe: '', slug: '', icon: '', isRestricted: false });
    setShowCategoryModal(true);
  };

  const startEditCategory = (cat) => {
    setEditingCategory(cat);
    setCategoryForm({
      name: cat.name,
      nameNe: cat.nameNe || '',
      slug: cat.slug,
      icon: cat.icon || '',
      isRestricted: cat.isRestricted || false,
    });
  };

  const handleSaveCategory = async (e) => {
    e.preventDefault();
    try {
      if (editingCategory) {
        const res = await api.put(`/categories/${editingCategory._id}`, categoryForm);
        if (res.data.success) {
          setCategories(categories.map((c) => (c._id === editingCategory._id ? res.data.category : c)));
          setEditingCategory(null);
          setCategoryForm({ name: '', nameNe: '', slug: '', icon: '', isRestricted: false });
          showToast(`Category "${res.data.category.name}" updated`, 'success');
        }
      } else {
        const res = await api.post('/categories', categoryForm);
        if (res.data.success) {
          setCategories([...categories, res.data.category]);
          setCategoryForm({ name: '', nameNe: '', slug: '', icon: '', isRestricted: false });
          showToast(`Category "${res.data.category.name}" created`, 'success');
        }
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Category Save Error', 'danger');
    }
  };

  const handleDeleteCategory = async (id, name) => {
    const confirmed = await showConfirm(
      `Delete category "${name}"? Products assigned to this category will remain, but may need reassignment.`,
      'Delete Category',
      true,
      'Delete Category',
      'Cancel'
    );
    if (!confirmed) return;
    try {
      const res = await api.delete(`/categories/${id}`);
      if (res.data.success) {
        setCategories(categories.filter((c) => c._id !== id));
        if (selectedCategory === id) setSelectedCategory('');
        showToast(`Category "${name}" removed`, 'success');
      }
    } catch (err) {
      showAlert(err.response?.data?.message || err.message, 'Delete Category Failed', 'danger');
    }
  };

  // Filtered Products
  const filteredProducts = products.filter((p) => {
    const matchesCategory = selectedCategory
      ? (p.category?._id === selectedCategory || p.category === selectedCategory)
      : true;
    const q = searchQuery.toLowerCase();
    const matchesSearch = searchQuery
      ? p.name.toLowerCase().includes(q) || (p.nameNe && p.nameNe.toLowerCase().includes(q))
      : true;
    return matchesCategory && matchesSearch;
  });

  return (
    <>
      <Navbar title="Products & Inventory Catalog" onReplaySplash={onReplaySplash} />
      <div className="page-body">
        {loading ? (
          <ValleyLoader text="Loading live catalog from database..." />
        ) : (
          <>
            {/* Header Controls */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '20px',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              {/* Category Filter Chips */}
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', alignItems: 'center' }}>
                <button
                  onClick={() => setSelectedCategory('')}
                  className={`btn btn-sm ${selectedCategory === '' ? 'btn-brand' : 'btn-secondary'}`}
                >
                  All Items ({products.length})
                </button>
                {categories.map((c) => (
                  <button
                    key={c._id}
                    onClick={() => setSelectedCategory(c._id)}
                    className={`btn btn-sm ${selectedCategory === c._id ? 'btn-brand' : 'btn-secondary'}`}
                  >
                    {c.name}
                  </button>
                ))}
              </div>

              {/* Actions */}
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Filter products..."
                  style={{ width: '200px' }}
                />
                <button onClick={openCategoryManager} className="btn btn-secondary btn-sm">
                  Manage Categories
                </button>
                <button onClick={openAddProductModal} className="btn btn-primary btn-sm">
                  + Add Product
                </button>
              </div>
            </div>

            {/* Product Table */}
            <div className="table-card">
              <div className="table-responsive">
                <table>
                  <thead>
                    <tr>
                      <th>Product</th>
                      <th>Category</th>
                      <th>Price (NPR)</th>
                      <th>Stock Qty</th>
                      <th>Classification</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredProducts.length === 0 ? (
                      <tr>
                        <td colSpan="6" style={{ textAlign: 'center', padding: '36px', color: '#1F2A44' }}>
                          No products found matching filter criteria.
                        </td>
                      </tr>
                    ) : (
                      filteredProducts.map((p) => (
                        <tr key={p._id}>
                          <td>
                            <div style={{ fontWeight: 500, color: '#003893' }}>{p.name}</div>
                            {p.nameNe && (
                              <div style={{ fontSize: '11px', color: '#1F2A44' }}>{p.nameNe}</div>
                            )}
                            <div style={{ fontSize: '11px', color: '#1F2A44' }}>
                              Unit: {p.unit || 'item'}
                            </div>
                          </td>
                          <td>
                            <span className="badge badge-neutral">
                              {p.category?.name || 'Unassigned'}
                            </span>
                          </td>
                          <td style={{ fontWeight: 700, color: '#FF6B1A' }}>
                            Rs. {p.price}
                            {p.discountPrice && (
                              <span style={{ fontSize: '11px', color: '#1F2A44', marginLeft: '6px' }}>
                                (Sale: Rs. {p.discountPrice})
                              </span>
                            )}
                          </td>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <button
                                onClick={() => adjustStock(p, -1)}
                                className="btn btn-secondary btn-sm"
                                style={{ padding: '2px 8px', minHeight: '26px' }}
                                title="Decrease stock"
                              >
                                -
                              </button>
                              <span style={{ fontWeight: 700, minWidth: '32px', textAlign: 'center' }}>
                                {p.stock}
                              </span>
                              <button
                                onClick={() => adjustStock(p, 5)}
                                className="btn btn-secondary btn-sm"
                                style={{ padding: '2px 8px', minHeight: '26px' }}
                                title="Add 5 units"
                              >
                                +5
                              </button>
                            </div>
                          </td>
                          <td>
                            {p.isAlcohol ? (
                              <span className="badge badge-accent">
                                Alcohol ({p.alcoholPercentage || 0}% ABV)
                              </span>
                            ) : (
                              <span className="badge badge-neutral">Standard</span>
                            )}
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: '6px' }}>
                              <button
                                onClick={() => openEditProductModal(p)}
                                className="btn btn-secondary btn-sm"
                              >
                                Edit
                              </button>
                              <button
                                onClick={() => handleDeleteProduct(p._id, p.name)}
                                className="btn btn-secondary btn-sm"
                                style={{ color: '#FF6B1A' }}
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Product Add / Edit Modal */}
            {showProductModal && (
              <div className="modal-overlay">
                <div className="modal-content">
                  <div className="modal-header">
                    <h3 className="modal-title">
                      {editingProduct ? 'Edit Catalog Product' : 'Add New Product to DB'}
                    </h3>
                    <button
                      onClick={() => setShowProductModal(false)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  <form onSubmit={handleSaveProduct}>
                    <div className="form-group">
                      <label className="form-label">Product Name (English) *</label>
                      <input
                        type="text"
                        required
                        value={productForm.name}
                        onChange={(e) => setProductForm({ ...productForm, name: e.target.value })}
                        placeholder="e.g. Gorkha Strong Beer (650ml)"
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Product Name (Nepali)</label>
                      <input
                        type="text"
                        value={productForm.nameNe}
                        onChange={(e) => setProductForm({ ...productForm, nameNe: e.target.value })}
                        placeholder="[NEPALI TEXT]"
                      />
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Category *</label>
                        <select
                          required
                          value={productForm.category}
                          onChange={(e) => setProductForm({ ...productForm, category: e.target.value })}
                        >
                          <option value="">Select Category</option>
                          {categories.map((c) => (
                            <option key={c._id} value={c._id}>
                              {c.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="form-label">Price (NPR) *</label>
                        <input
                          type="number"
                          required
                          value={productForm.price}
                          onChange={(e) => setProductForm({ ...productForm, price: e.target.value })}
                          placeholder="380"
                        />
                      </div>
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Stock Quantity</label>
                        <input
                          type="number"
                          value={productForm.stock}
                          onChange={(e) => setProductForm({ ...productForm, stock: e.target.value })}
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Unit / Packaging</label>
                        <input
                          type="text"
                          value={productForm.unit}
                          onChange={(e) => setProductForm({ ...productForm, unit: e.target.value })}
                          placeholder="e.g. 650ml bottle"
                        />
                      </div>
                    </div>

                    <div
                      style={{
                        background: '#FFFFFF',
                        border: '1px solid #D1D5DB',
                        padding: '12px',
                        borderRadius: '4px',
                        marginBottom: '16px',
                      }}
                    >
                      <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontWeight: 500 }}>
                        <input
                          type="checkbox"
                          checked={productForm.isAlcohol}
                          onChange={(e) => setProductForm({ ...productForm, isAlcohol: e.target.checked })}
                        />
                        Is this an Alcoholic Beverage? (Enforces 18+ Verification)
                      </label>

                      {productForm.isAlcohol && (
                        <div style={{ marginTop: '10px' }}>
                          <label className="form-label">Alcohol by Volume (ABV %)</label>
                          <input
                            type="number"
                            step="0.1"
                            value={productForm.alcoholPercentage}
                            onChange={(e) => setProductForm({ ...productForm, alcoholPercentage: e.target.value })}
                            placeholder="e.g. 5.0"
                          />
                        </div>
                      )}
                    </div>

                    {/* Multi-Image Drag & Drop and Main Image Selector */}
                    <div className="form-group" style={{ marginTop: '16px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                        <label className="form-label" style={{ marginBottom: 0 }}>
                          Product Photos ({productForm.images.length} attached)
                        </label>
                        <span style={{ fontSize: '11px', color: '#003893', fontWeight: 600 }}>
                          Select any image to mark as Main Cover
                        </span>
                      </div>

                      {/* Drag & Drop Upload Zone */}
                      <div
                        onDragOver={(e) => {
                          e.preventDefault();
                          setDragActive(true);
                        }}
                        onDragLeave={(e) => {
                          e.preventDefault();
                          setDragActive(false);
                        }}
                        onDrop={(e) => {
                          e.preventDefault();
                          setDragActive(false);
                          handleImageFiles(e.dataTransfer.files);
                        }}
                        onClick={() => document.getElementById('product-file-input').click()}
                        style={{
                          border: dragActive ? '2px dashed #FF6B1A' : '2px dashed #003893',
                          background: dragActive ? '#FFF5EB' : '#FFFFFF',
                          padding: '20px 16px',
                          textAlign: 'center',
                          borderRadius: '4px',
                          cursor: 'pointer',
                          transition: 'all 0.15s ease-in-out',
                        }}
                      >
                        <input
                          id="product-file-input"
                          type="file"
                          multiple
                          accept="image/*"
                          style={{ display: 'none' }}
                          onChange={(e) => handleImageFiles(e.target.files)}
                        />
                        <div style={{ color: '#003893', fontWeight: 700, fontSize: '13px', marginBottom: '4px' }}>
                          Drag and drop multiple product images here
                        </div>
                        <div style={{ fontSize: '12px', color: '#1F2A44' }}>
                          or <span style={{ color: '#FF6B1A', textDecoration: 'underline', fontWeight: 600 }}>click to browse from computer</span> (PNG, JPG, WEBP)
                        </div>
                      </div>

                      {/* Remote URL Quick-Add Row */}
                      <div style={{ display: 'flex', gap: '8px', marginTop: '10px' }}>
                        <input
                          type="url"
                          value={urlInput}
                          onChange={(e) => setUrlInput(e.target.value)}
                          placeholder="Or paste an image link (https://...)"
                          style={{ flex: 1, fontSize: '12px', padding: '8px 10px' }}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              e.preventDefault();
                              handleAddUrlImage();
                            }
                          }}
                        />
                        <button
                          type="button"
                          onClick={handleAddUrlImage}
                          className="btn btn-secondary btn-sm"
                          style={{ whiteSpace: 'nowrap' }}
                        >
                          + Add URL
                        </button>
                      </div>

                      {/* Attached Images Gallery & Main Selector */}
                      {productForm.images.length > 0 ? (
                        <div
                          style={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))',
                            gap: '12px',
                            marginTop: '14px',
                            maxHeight: '260px',
                            overflowY: 'auto',
                            padding: '4px',
                          }}
                        >
                          {productForm.images.map((imgUrl, idx) => {
                            const isMain = idx === productForm.mainImageIndex;
                            return (
                              <div
                                key={idx}
                                style={{
                                  position: 'relative',
                                  border: isMain ? '2px solid #FF6B1A' : '1px solid #D1D5DB',
                                  borderRadius: '4px',
                                  overflow: 'hidden',
                                  background: '#FFFFFF',
                                  display: 'flex',
                                  flexDirection: 'column',
                                }}
                              >
                                {isMain && (
                                  <div
                                    style={{
                                      position: 'absolute',
                                      top: '6px',
                                      left: '6px',
                                      zIndex: 2,
                                      background: '#FF6B1A',
                                      color: '#FFFFFF',
                                      fontSize: '9px',
                                      fontWeight: 700,
                                      padding: '2px 6px',
                                      borderRadius: '2px',
                                      letterSpacing: '0.5px',
                                      textTransform: 'uppercase',
                                    }}
                                  >
                                    Main Cover
                                  </div>
                                )}

                                <div style={{ height: '90px', width: '100%', background: '#F8FAFC' }}>
                                  <img
                                    src={imgUrl}
                                    alt={`Product preview ${idx + 1}`}
                                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                    onError={(e) => {
                                      e.target.style.display = 'none';
                                    }}
                                  />
                                </div>

                                <div style={{ padding: '6px', display: 'flex', gap: '4px', flexDirection: 'column' }}>
                                  {!isMain ? (
                                    <button
                                      type="button"
                                      onClick={() => handleSetMainImage(idx)}
                                      className="btn btn-secondary btn-sm"
                                      style={{ fontSize: '10px', padding: '3px 6px', width: '100%' }}
                                    >
                                      Set as Main
                                    </button>
                                  ) : (
                                    <div
                                      style={{
                                        fontSize: '10px',
                                        fontWeight: 600,
                                        color: '#003893',
                                        textAlign: 'center',
                                        padding: '4px 0',
                                      }}
                                    >
                                      Selected Hero
                                    </div>
                                  )}

                                  <button
                                    type="button"
                                    onClick={() => handleRemoveImage(idx)}
                                    style={{
                                      background: '#FFFFFF',
                                      border: '1px solid #D1D5DB',
                                      color: '#1F2A44',
                                      fontSize: '10px',
                                      padding: '3px 6px',
                                      borderRadius: '2px',
                                      cursor: 'pointer',
                                      width: '100%',
                                    }}
                                  >
                                    Remove
                                  </button>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      ) : (
                        <div
                          style={{
                            marginTop: '8px',
                            fontSize: '11px',
                            color: '#1F2A44',
                            opacity: 0.7,
                          }}
                        >
                          No photos attached yet. You can attach multiple photos (the first image is displayed on catalog cards).
                        </div>
                      )}
                    </div>

                    <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                      <button
                        type="button"
                        onClick={() => setShowProductModal(false)}
                        className="btn btn-secondary"
                        style={{ flex: 1 }}
                      >
                        Cancel
                      </button>
                      <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>
                        {editingProduct ? 'Save Changes' : 'Create Product in DB'}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}

            {/* Category Management Modal (Full CRUD) */}
            {showCategoryModal && (
              <div className="modal-overlay">
                <div className="modal-content" style={{ maxWidth: '640px' }}>
                  <div className="modal-header">
                    <h3 className="modal-title">Manage Product Categories</h3>
                    <button
                      onClick={() => setShowCategoryModal(false)}
                      className="btn btn-secondary btn-sm"
                    >
                      Close
                    </button>
                  </div>

                  {/* Add / Edit Category Form */}
                  <form
                    onSubmit={handleSaveCategory}
                    style={{
                      background: '#FFFFFF',
                      border: '1px solid #D1D5DB',
                      padding: '16px',
                      borderRadius: '4px',
                      marginBottom: '20px',
                    }}
                  >
                    <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893', marginBottom: '12px' }}>
                      {editingCategory ? `Editing: ${editingCategory.name}` : '+ Add New Category to DB'}
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Name (English) *</label>
                        <input
                          type="text"
                          required
                          value={categoryForm.name}
                          onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
                          placeholder="e.g. Mixers & Soda"
                        />
                      </div>
                      <div className="form-group">
                        <label className="form-label">Name (Nepali)</label>
                        <input
                          type="text"
                          value={categoryForm.nameNe}
                          onChange={(e) => setCategoryForm({ ...categoryForm, nameNe: e.target.value })}
                          placeholder="[NEPALI TEXT]"
                        />
                      </div>
                    </div>

                    <div className="form-grid">
                      <div className="form-group">
                        <label className="form-label">Slug</label>
                        <input
                          type="text"
                          value={categoryForm.slug}
                          onChange={(e) => setCategoryForm({ ...categoryForm, slug: e.target.value })}
                          placeholder="e.g. mixers-soda"
                        />
                      </div>
                      <div className="form-group">
                        <label className="form-label">Classification</label>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', height: '44px', fontWeight: 500, fontSize: '12px' }}>
                          <input
                            type="checkbox"
                            checked={categoryForm.isRestricted}
                            onChange={(e) => setCategoryForm({ ...categoryForm, isRestricted: e.target.checked })}
                          />
                          Alcohol Category (18+ Mandatory)
                        </label>
                      </div>
                    </div>

                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button type="submit" className="btn btn-primary btn-sm">
                        {editingCategory ? 'Update Category' : 'Create Category'}
                      </button>
                      {editingCategory && (
                        <button
                          type="button"
                          onClick={() => {
                            setEditingCategory(null);
                            setCategoryForm({ name: '', nameNe: '', slug: '', icon: '', isRestricted: false });
                          }}
                          className="btn btn-secondary btn-sm"
                        >
                          Cancel Edit
                        </button>
                      )}
                    </div>
                  </form>

                  {/* Existing Categories Table */}
                  <div style={{ fontWeight: 700, fontSize: '13px', color: '#003893', marginBottom: '8px' }}>
                    Existing Categories ({categories.length})
                  </div>
                  <table style={{ border: '1px solid #D1D5DB' }}>
                    <thead>
                      <tr>
                        <th>Category</th>
                        <th>Slug</th>
                        <th>Classification</th>
                        <th>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {categories.map((c) => (
                        <tr key={c._id}>
                          <td>
                            <div style={{ fontWeight: 500 }}>{c.name}</div>
                            {c.nameNe && <div style={{ fontSize: '11px', color: '#1F2A44' }}>{c.nameNe}</div>}
                          </td>
                          <td style={{ fontSize: '12px', fontFamily: 'monospace' }}>{c.slug}</td>
                          <td>
                            {c.isRestricted ? (
                              <span className="badge badge-accent">Alcohol</span>
                            ) : (
                              <span className="badge badge-neutral">Standard</span>
                            )}
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: '6px' }}>
                              <button
                                type="button"
                                onClick={() => startEditCategory(c)}
                                className="btn btn-secondary btn-sm"
                              >
                                Edit
                              </button>
                              <button
                                type="button"
                                onClick={() => handleDeleteCategory(c._id, c.name)}
                                className="btn btn-secondary btn-sm"
                                style={{ color: '#FF6B1A' }}
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
};

export default Products;
