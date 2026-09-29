// The shim must be evaluated before `@peculiar/x509` (module evaluation follows
// declaration order). Import X.509 types and classes from here, never from the
// package directly.
import './reflectShim';

export { X509Certificate } from '@peculiar/x509';
