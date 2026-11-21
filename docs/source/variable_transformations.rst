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

.. mat:autofolder:: +bids/

.. autofunction:: +bids/transformers.m

.. mat:autofolder:: +bids/+transformers_list/

Basic operations
================

- Add
- Subtract
- Multiply
- Divide
- Power

.. autofunction:: +bids/+transformers_list/Basic.m

Logical operations
==================

- And
- Or
- Not

.. autofunction:: +bids/+transformers_list/Logical.m


Munge operations
================

Transformations that primarily involve manipulating/munging variables into
other formats or shapes.

Assign
------

.. autofunction:: +bids/+transformers_list/Assign.m

Concatenate
-----------

.. autofunction:: +bids/+transformers_list/Concatenate.m

Copy
----

.. autofunction:: +bids/+transformers_list/Copy.m

Delete
------

.. autofunction:: +bids/+transformers_list/Delete.m

DropNA
------

.. autofunction:: +bids/+transformers_list/Drop_na.m

Factor
------

.. autofunction:: +bids/+transformers_list/Factor.m

Filter
-------

.. autofunction:: +bids/+transformers_list/Filter.m

Label identical rows
--------------------

.. autofunction:: +bids/+transformers_list/Label_identical_rows.m

Merge identical rows
--------------------

.. autofunction:: +bids/+transformers_list/Merge_identical_rows.m

Replace
-------

.. autofunction:: +bids/+transformers_list/Replace.m

Select
------

.. autofunction:: +bids/+transformers_list/Select.m

Split
-----

.. autofunction:: +bids/+transformers_list/Split.m


Compute operations
==================

Transformations that primarily involve numerical computation on variables.

Constant
--------

.. autofunction:: +bids/+transformers_list/Constant.m

Mean
-----

.. autofunction:: +bids/+transformers_list/Mean.m

Product
-------

.. autofunction:: +bids/+transformers_list/Product.m

Scale
-----

.. autofunction:: +bids/+transformers_list/Scale.m

Std
---

.. autofunction:: +bids/+transformers_list/Std.m

Sum
---

.. autofunction:: +bids/+transformers_list/Sum.m

Threshold
---------

.. autofunction:: +bids/+transformers_list/Threshold.m
