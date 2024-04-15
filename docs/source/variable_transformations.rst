Variable transformations
************************

Those transformers are meant to be used to manipulate the content of TSV files
once loaded as structure with ``bids.util.tsvread``.

They are mostly meant to be used to implement the transformations
described in BIDS stats models
but can also be used to manipulate TSV files in batches.

More information on how they function can be found
in the `variable-transform repository <https://github.com/bids-standard/variable-transform>`_.

The behavior and their "call" in JSON should (hopefully) be fairly close to the
`pybids-transformers <https://docs.google.com/document/d/1uxN6vPWbC7ciAx2XWtT5Y-lBrdckZKpPdNUNpwRxHoU/>`_.

Applying transformations
========================

An "array" of transformations can be applied one after the other using
``bids.transformers()``.

.. automodule:: +bids

.. autofunction:: transformers

.. automodule:: +bids.+transformers_list

Basic operations
================

- Add
- Subtract
- Multiply
- Divide
- Power

.. autofunction:: Basic

Logical operations
==================

- And
- Or
- Not

.. autofunction:: Logical


Munge operations
================

Transformations that primarily involve manipulating/munging variables into
other formats or shapes.

Assign
------

.. autofunction:: Assign

Concatenate
-----------

.. autofunction:: Concatenate

Copy
----

.. autofunction:: Copy

Delete
------

.. autofunction:: Delete

DropNA
------

.. autofunction:: Drop_na

Factor
------

.. autofunction:: Factor

Filter
-------

.. autofunction:: Filter

Label identical rows
--------------------

.. autofunction:: Label_identical_rows

Merge identical rows
--------------------

.. autofunction:: Merge_identical_rows

Replace
-------

.. autofunction:: Replace

Select
------

.. autofunction:: Select

Split
-----

.. autofunction:: Split


Compute operations
==================

Transformations that primarily involve numerical computation on variables.

Constant
--------

.. autofunction:: Constant

Mean
-----

.. autofunction:: Mean

Product
-------

.. autofunction:: Product

Scale
-----

.. autofunction:: Scale

Std
---

.. autofunction:: Std

Sum
---

.. autofunction:: Sum

Threshold
---------

.. autofunction:: Threshold
