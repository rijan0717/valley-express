import React, { useState } from 'react';
import { PackageIcon } from './Icons';

/// Product detail sheet for the mobile simulator. Sits inside the phone frame
/// rather than over the whole dashboard, so it reads as part of the app.
const ProductDetailSheet = ({ product, onClose, onAdd }) => {
  const [quantity, setQuantity] = useState(1);

  if (!product) return null;

  const price = product.price || 0;
  const discount = product.discountPrice || product.mrp || 0;
  const hasDiscount = discount > price;
  const inStock = (product.stock ?? 0) > 0 || product.stock === undefined;

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: 'rgba(24, 28, 46, 0.45)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'flex-end',
        zIndex: 20,
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: '#FFFFFF',
          borderTopLeftRadius: '20px',
          borderTopRightRadius: '20px',
          maxHeight: '88%',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
        }}
      >
        {/* Grab handle */}
        <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 4px' }}>
          <div style={{ width: '38px', height: '4px', borderRadius: '2px', background: '#D1D5DB' }} />
        </div>

        <div style={{ overflowY: 'auto', padding: '4px 16px 12px' }}>
          <div
            style={{
              height: '150px',
              width: '100%',
              background: '#F0F5FA',
              borderRadius: '16px',
              overflow: 'hidden',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              position: 'relative',
              marginBottom: '14px',
            }}
          >
            {product.images && product.images.length > 0 ? (
              <img
                src={product.images[0]}
                alt={product.name}
                style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                onError={(e) => {
                  e.target.style.display = 'none';
                }}
              />
            ) : (
              <PackageIcon size={42} />
            )}
            {product.isAlcohol && (
              <span
                style={{
                  position: 'absolute',
                  top: '10px',
                  left: '10px',
                  background: '#FF6B1A',
                  color: '#FFFFFF',
                  fontSize: '10px',
                  fontWeight: 700,
                  padding: '3px 7px',
                  borderRadius: '5px',
                }}
              >
                18+
              </span>
            )}
          </div>

          <div style={{ fontWeight: 700, fontSize: '17px', color: '#181C2E', lineHeight: 1.25 }}>
            {product.name}
          </div>
          {product.nameNe && (
            <div style={{ fontSize: '12px', color: '#646982', marginTop: '3px' }}>
              {product.nameNe}
            </div>
          )}

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '10px' }}>
            <span style={{ fontWeight: 700, fontSize: '20px', color: '#FF6B1A' }}>
              Rs. {price}
            </span>
            {hasDiscount && (
              <span style={{ fontSize: '13px', color: '#A0A5BA', textDecoration: 'line-through' }}>
                Rs. {discount}
              </span>
            )}
            <span
              style={{
                marginLeft: 'auto',
                fontSize: '10px',
                fontWeight: 700,
                textTransform: 'uppercase',
                letterSpacing: '0.4px',
                color: inStock ? '#16A34A' : '#EF4444',
              }}
            >
              {inStock ? 'In stock' : 'Out of stock'}
            </span>
          </div>

          {/* Attribute rows */}
          <div
            style={{
              marginTop: '14px',
              border: '1px solid #E2E8F0',
              borderRadius: '12px',
              overflow: 'hidden',
            }}
          >
            {[
              ['Unit size', product.unit || '650ml bottle'],
              ['Category', product.category?.name || 'General'],
              product.stock !== undefined ? ['Available stock', `${product.stock}`] : null,
              product.brand ? ['Brand', product.brand] : null,
            ]
              .filter(Boolean)
              .map(([label, value], i, arr) => (
                <div
                  key={label}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    padding: '10px 12px',
                    fontSize: '12px',
                    borderBottom: i === arr.length - 1 ? 'none' : '1px solid #E2E8F0',
                  }}
                >
                  <span style={{ color: '#646982' }}>{label}</span>
                  <span style={{ fontWeight: 600, color: '#181C2E' }}>{value}</span>
                </div>
              ))}
          </div>

          {product.description && (
            <p style={{ fontSize: '12px', color: '#646982', lineHeight: 1.6, marginTop: '14px' }}>
              {product.description}
            </p>
          )}

          {product.isAlcohol && (
            <div
              style={{
                marginTop: '14px',
                padding: '10px 12px',
                borderRadius: '10px',
                border: '1px solid #FF6B1A',
                color: '#FF6B1A',
                fontSize: '11px',
                fontWeight: 600,
                lineHeight: 1.5,
              }}
            >
              Age-restricted item. The rider will check a physical 18+ ID at the door before
              handing this over.
            </div>
          )}
        </div>

        {/* Sticky footer: quantity stepper and add button */}
        <div
          style={{
            borderTop: '1px solid #E2E8F0',
            padding: '10px 16px',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            background: '#FFFFFF',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              border: '1px solid #D1D5DB',
              borderRadius: '10px',
            }}
          >
            <button
              type="button"
              onClick={() => setQuantity((q) => Math.max(1, q - 1))}
              aria-label="Decrease quantity"
              style={stepperStyle}
            >
              −
            </button>
            <span style={{ minWidth: '26px', textAlign: 'center', fontWeight: 700, fontSize: '13px' }}>
              {quantity}
            </span>
            <button
              type="button"
              onClick={() => setQuantity((q) => q + 1)}
              aria-label="Increase quantity"
              style={stepperStyle}
            >
              +
            </button>
          </div>

          <button
            type="button"
            onClick={(e) => onAdd(quantity, e.currentTarget)}
            style={{
              flex: 1,
              minHeight: '44px',
              borderRadius: '12px',
              border: 'none',
              background: '#FF6B1A',
              color: '#FFFFFF',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            Add {quantity} · Rs. {price * quantity}
          </button>
        </div>
      </div>
    </div>
  );
};

const stepperStyle = {
  width: '32px',
  height: '36px',
  border: 'none',
  background: 'transparent',
  fontSize: '17px',
  fontWeight: 700,
  color: '#181C2E',
  cursor: 'pointer',
};

export default ProductDetailSheet;
