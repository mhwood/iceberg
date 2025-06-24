.. iceberg documentation master file, created by
   sphinx-quickstart on Thu May 29 14:42:04 2025.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

iceberg Documentation
=====================

Welcome to the documentation page for the development of an iceberg model for MITgcm. This
documentation reflects the MITgcm package, example configurations, and associated tools
provided on the `iceberg <https://github.com/mhwood/iceberg>`_ Github repository.


Motivation
^^^^^^^^^^
Icebergs represent an import forcing on ocean properties around ice sheets. However, they are
not currently built into MITgcm in package wide range of applications that can be used across
scales from fjord-scale models to global circulation models. In this project, our goal is 
to create a general iceberg package that fit this need.

Existing iceberg Packages
^^^^^^^^^^^^^^^^^^^^^^^^^
Currently, there are two iceberg packages that have been developed and used in MITgcm. 

.. _iceberg_advection:

===========================
Documentation Contents
===========================

.. toctree::
   :maxdepth: 2
   :numbered: 5

   usage/usage
   model/model_overview
   sample_models/configurations
   utilities/overview


