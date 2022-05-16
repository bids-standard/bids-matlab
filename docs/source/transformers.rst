Transformers
************

Those transformers are meant to be used to manipulate the content of TSV files once
loaded as structure with ``bids.util.tsvread``.

They are mostly meant to be used to implement the transformations described in BIDS 
stats models but can also be used to manipulate TSV files in batches.

For each type of transformer, we describe first how they are meant to be "called"
in the JSON file of the BIDS stats model.

There is also an code example to show how to use them.

The behavior and their "call" in JSON should (hopefully) be fairly close to the 
`pybids-transformers <https://docs.google.com/document/d/1uxN6vPWbC7ciAx2XWtT5Y-lBrdckZKpPdNUNpwRxHoU/>`_.

Applying transformations
========================

An "array" of transformations can be applied one after the other using
``bids.transformers()``.

.. automodule:: +bids

.. autofunction:: transformers

.. automodule:: +bids.+transformers

Basic operations
================

- Add 
- Subtract
- Multiply
- Divide
- Power

.. autofunction:: basic

Logical operations
==================

- And
- Or
- Not

.. autofunction:: logical


Munge operations
================

Transformations that primarily involve manipulating/munging variables into
other formats or shapes.

Assign
------

.. autofunction:: assign

Concatenate
-----------

.. autofunction:: concatenate

Copy
----

.. autofunction:: copy

Delete
------

.. autofunction:: delete

Drop_na
-------

.. autofunction:: drop_na

Factor
------

.. autofunction:: factor

Filter
-------

.. autofunction:: filter

Replace
-------

.. autofunction:: replace

Select
------

.. autofunction:: select

Split
-----

.. autofunction:: split


Compute operations
==================

Transformations that primarily involve numerical computation on variables.

Constant
--------

.. autofunction:: constant

Mean
-----

.. autofunction:: mean

Product
-------

.. autofunction:: product

Scale
-----

.. autofunction:: scale

Std
---

.. autofunction:: std

Sum
---

.. autofunction:: sum

Threshold
---------

.. autofunction:: threshold
