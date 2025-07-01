Advection
=========

This is the module that simulate the movement of the iceberg using external conditions and physical characteristic of
the ocean.

Variable Notation List
-----------------------

Position and Distance
~~~~~~~~~~~~~~~~~~~~~~~

- **dist_i** : distance moved in x-direction
- **dist_j** : distance moved in y-direction
- **ib_iT** : x position of iceberg (on tile)
- **ib_jT** : y position of iceberg (on tile)
- **i1** : integer value of ib_iT
- **j1** : integer value of ib_jT

Velocities
~~~~~~~~~~

- **uvel_w** : zonal ocean velocity at iceberg (m s\ :sup:`-1`)
- **vvel_w** : meridional ocean velocity at iceberg (m s\ :sup:`-1`)
- **Vel_w** : absolute ocean velocity at iceberg (m s\ :sup:`-1`)
- **uvel_a** : zonal wind speed at iceberg (m s\ :sup:`-1`)
- **vvel_a** : meridional wind speed at iceberg (m s\ :sup:`-1`)
- **Vel_a** : absolute wind velocity at iceberg (m s\ :sup:`-1`)
- **uvel_si** : sea ice zonal speed at iceberg (m s\ :sup:`-1`)
- **vvel_si** : sea ice meridional speed at iceberg (m s\ :sup:`-1`)

Relative Velocities
~~~~~~~~~~~~~~~~~~~

- **uvel_w_r** : relative zonal velocity (ocean minus iceberg) (m s\ :sup:`-1`)
- **vvel_w_r** : relative meridional velocity (ocean minus iceberg) (m s\ :sup:`-1`)
- **uvel_a_r** : relative zonal velocity (wind minus iceberg) (m s\ :sup:`-1`)
- **vvel_a_r** : relative meridional velocity (wind minus iceberg) (m s\ :sup:`-1`)
- **uvel_si_r** : relative zonal velocity (sea ice minus iceberg) (m s\ :sup:`-1`)
- **vvel_si_r** : relative meridional velocity (sea ice minus iceberg) (m s\ :sup:`-1`)
- **Vel_w_r** : absolute relative ocean velocity at iceberg (m s\ :sup:`-1`)
- **Vel_a_r** : absolute relative wind velocity at iceberg (m s\ :sup:`-1`)
- **Vel_si_r** : absolute relative sea ice velocity at iceberg (m s\ :sup:`-1`)

Sea Ice and Coriolis Parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **ib_SIheff** : local (interpolated) height of sea ice at iceberg (m)
- **ib_SIarea** : local (interpolated) concentration of sea ice at iceberg (0–1)
- **ib_cori** : local (interpolated) Coriolis parameter at iceberg (rad s\ :sup:`-1`)

Mass and Forces
~~~~~~~~~~~~~~~~

- **ib_mass** : mass of iceberg (kg)
- **ib_FU** : total drag force (U direction) (kg m s\ :sup:`-2`)
- **ib_FV** : total drag force (V direction) (kg m s\ :sup:`-2`)
- **ib_FwU** : water drag force (U direction) (kg m s\ :sup:`-2`)
- **ib_FwV** : water drag force (V direction) (kg m s\ :sup:`-2`)
- **ib_FwU_z** : water drag force (U direction) at each vertical level (kg m s\ :sup:`-2`)
- **ib_FwV_z** : water drag force (V direction) at each vertical level (kg m s\ :sup:`-2`)
- **ib_FaU** : atmospheric drag force (U direction) (kg m s\ :sup:`-2`)
- **ib_FaV** : atmospheric drag force (V direction) (kg m s\ :sup:`-2`)
- **ib_FiU** : sea ice drag force (U direction) (kg m s\ :sup:`-2`)
- **ib_FiV** : sea ice drag force (V direction) (kg m s\ :sup:`-2`)
- **ib_FrU** : wave radiation drag force (U direction) (kg m s\ :sup:`-2`)
- **ib_FrV** : wave radiation drag force (V direction) (kg m s\ :sup:`-2`)
- **ib_FcU** : Coriolis force (U direction) (kg m s\ :sup:`-2`)
- **ib_FcV** : Coriolis force (V direction) (kg m s\ :sup:`-2`)
- **ib_FpU** : pressure gradient force (U direction) (kg m s\ :sup:`-2`)
- **ib_FpV** : pressure gradient force (V direction) (kg m s\ :sup:`-2`)

Wave Parameters
~~~~~~~~~~~~~~~

- **Lw** : empirical wavelength
- **Cr** : variable wavelength coefficient
- **Wamp** : wave amplitude (m), half of wave height
- **Wh** : wave height (m)

Sea Surface Slope
~~~~~~~~~~~~~~~~~

- **grad_u** : sea surface slope in x-direction at iceberg (m/m)
- **grad_v** : sea surface slope in y-direction at iceberg (m/m)

Geometry and Drag Areas
~~~~~~~~~~~~~~~~~~~~~~~~

- **ib_perpL_x** : length of iceberg perpendicular to x-axis
- **ib_perpL_y** : length of iceberg perpendicular to y-axis
- **angle** : inverse tangent (atan2) of vvel_w and uvel_w for drag calculation
- **sail_area_x** : area of iceberg above water in x-direction
- **sail_area_y** : area of iceberg above water in y-direction

I/O Variables
~~~~~~~~~~~~~

- **varOUT** : temporary variable passed from interpolation scheme
- **varOUTu** : temporary variable passed back from collision scheme (U direction)
- **varOUTv** : temporary variable passed back from collision scheme (V direction)
- **collide** : flag passed from collision scheme (set to 1 if collision detected)

Grid and Keel Parameters
~~~~~~~~~~~~~~~~~~~~~~~~

- **ib_R_low** : interpolatedcal levels penetrated by iceberg
- **ib_nlvl_rl** : real*4 repres water depth at iceberg location (m)
- **ib_dxC** : interpolated grid spacing in x-direction at iceberg
- **ib_dyC** : interpolated grid spacing in y-direction at iceberg
- **thkR** : vertical thickness of each water layer the iceberg penetrates
- **ib_nlvl** : number of vertientation of ib_nlvl
- **ib_RL** : ratio of number of levels iceberg penetrates to the 8-level keel model of Barker et al. (2004)
- **ib_keel** : keel depth calculated using second-order polynomial fit from Barker et al. (2004)
- **SAIL_LEVEL** : integer number of levels above water (typically assumed as 2)

.. _Advection Framework:

Dynamical Framework
-------------------

.. image:: ../images/IceBergAdvection.jpg
    :alt: Iceberg's equation of motion

| The motion of the iceberg (dragging force) is modeled using Newton’s second law, with forces including water drag, air drag, Coriolis, and pressure gradients as in Figure 1. The motion is calculated in both horizontal (ib_FU) and vertical (ib_FV) directions.

| By default, the iceberg's distance traveled and the dragging force's velocity are calculated using the following formulas:

.. math::

   \text{dist}_i = \frac{%
       \text{ib_uVel}(n) \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)
       + 0.5 \cdot \text{ib_FU} \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)^2%
   }{\text{ib_dxC}}

.. math::

   \text{dist}_j = \frac{%
       \text{ib_vVel}(n) \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)
       + 0.5 \cdot \text{ib_FV} \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)^2%
   }{\text{ib_dyC}}

.. math::

   \text{ib_uVel}(n) = \text{ib_uVel}(n) + \text{ib_FU} \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)

.. math::

   \text{ib_vVel}(n) = \text{ib_vVel}(n) + \text{ib_FV} \cdot \left( \frac{\Delta t}{\Delta t_{\text{ice}}} \right)


Drag Forces
------------

The drag forces are a sum of the forces acting on vertical walls (form drag) and horizontal surfaces (skin drag), determined by the general relationship:

.. math::

   F_x = 0.5 \cdot \rho_x \cdot \left[ C_{xv} \cdot A_v + C_{xh} \cdot A_h \right] \cdot |V_x - V_i| \cdot (V_x - V_i)

where:

- The subscript :math:`x` denotes the medium:

 - :math:`a` for atmosphere
 - :math:`w` for water (ocean)
 - :math:`i` for sea ice

- :math:`v` and :math:`h` refer to:

 - :math:`v`: vertical (form drag on side walls)
 - :math:`h`: horizontal (skin drag on the bottom)

Note: There is no horizontal drag (:math:`C_{ih}` term) applied for sea ice.

Water Drag Force
~~~~~~~~~~~~~~~~

- The thickness of sea ice is considered in the iceberg's draught at the surface, so that there is **no water drag force** applied where sea ice exists in the model (Martin and Adcroft, 2010).

- For the **bottom of the iceberg**, horizontal drag is included to represent skin drag effects (Martin and Adcroft, 2010).

- Icebergs are assumed to travel with their **long axis (length) aligned parallel** to the direction of the water velocity, which influences the projected area used in the drag calculation.

.. _Iceberg Keel Model:

Iceberg Keel Model
~~~~~~~~~~~~~~~~~~

Calculate shape of iceberg keel (``ib_keel``) based on second order polynomial fit to the top 8 levels of the keel model of
Barker et al. 2004) ``ib_keel`` is a fractional value of the absolute length at each depth. Multiply ``ib_keel`` by ``ib_perpL`` to
get an actual size (meters) at each level in the model. The keel above and below water has the general shape:

.. image:: ../images/KeelModel.png
    :alt: Keel Model illustration

The keel model will give a reduction in surface area over
the standard tabular shape below the waterline. The keel
area is ~77% of a tabular shape. This also alters
the mass of the iceberg. Note that this option will also
change the shape of the iceberg above the waterline to a two-layer sail that decreases in size with height.

| **Note:** Keel model only used when iceberg thickness > 30m to avoid prescribing unrealistic keel shapes. Below 30m thickness icebergs are assumed tabular (``ib_keel`` = **1**)

The iceberg keel depth is computed based on the number of vertical levels the iceberg penetrates into the water column, denoted as ``ib_nlvl``. This is first converted to a floating-point value:

.. math::

   \text{ib_nlvl_rl} = \text{ib_nlvl} \cdot 1.0

Then, a scaled quantity :math:`\text{ib\_RL}` is computed from the level index :math:`k` and the number of vertical levels:

.. math::

   \text{ib_RL} = k \cdot \left( \frac{8.0}{\text{ib_nlvl_rl}} \right)

Finally, the iceberg keel depth (``ib_keel``) is estimated using a quadratic formula based on ``ib_RL``:

.. math::

   \text{ib_keel} = -0.025 \cdot \text{ib_RL}^2 + 0.164 \cdot \text{ib_RL} + 0.78

Here:

- :math:`\text{ib_nlvl}` is the number of vertical levels the iceberg extends below the surface.
- :math:`k` is the current vertical level index.
- :math:`\text{ib_keel}` gives the estimated keel depth (in meters or model units).

Multi Level Ocean Drag
~~~~~~~~~~~~~~~~~~~~~~

| Consider ocean drag force at EVERY LEVEL in the ocean model that an iceberg penetrates. This is designed to give a more realistic advection pattern, compared to the purely surface ocean advection that is typically used in models.

| **Attention**: Depends on the set up in ``ICEBERG_OPTIONS.h`` file, the model can account for the multi-level

- If ``ALLOW_ICEBERG_MULTILEVEL`` is **ENABLED** , the model will calculate the water drag force using the keel model (Barker et al., 2004). (:ref:`Iceberg Keel Model`)

- If ``ALLOW_ICEBERG_MULTILEVEL`` is **DISABLED** OR ``USE_TABULAR_ICEBERGS`` is **ENABLED**, the iceberg's keel value ``ib_keel`` will be set to **1**

Water drag is calculated at each vertical level of the iceberg. The approach differs depending on whether the iceberg fully or partially penetrates the vertical cell.

For levels fully penetrated by the iceberg (i.e., :math:`k \ne \text{ib_nlvl}`), the vertical thickness of the layer is initialized as:

.. math::

   \text{thkR} = \Delta R_k

If sea ice is present at the surface (i.e., in the top model layer, :math:`k = 1`), its thickness is subtracted:

.. math::

   \text{if } k = 1 \text{ and } \text{ib_SIheff} < \text{thkR}, \quad \text{thkR} = \text{thkR} - \text{ib_SIheff}

If the resulting thickness is zero or negative, the model stops with an error.

The water drag force components in the x and y directions are then computed as:

.. math::

   \text{ib_FwU_z}(k) = 0.5 \cdot \rho_w \cdot C_{wv} \cdot \text{ib_perpL_x} \cdot \text{ib_keel} \cdot \text{thkR} \cdot V_r \cdot u_r

.. math::

   \text{ib_FwV_z}(k) = 0.5 \cdot \rho_w \cdot C_{wv} \cdot \text{ib_perpL_y} \cdot \text{ib_keel} \cdot \text{thkR} \cdot V_r \cdot v_r

For the bottom level of the iceberg (:math:`k = \text{ib_nlvl}`), which is only **partially penetrated**, the effective iceberg thickness in that cell is computed by subtracting the cumulative depth from the total iceberg draft:

.. math::

   \text{thkR} = \text{ib_dft} - \text{cumDepth}(k)

As with the top layer, sea ice is subtracted if present:

.. math::

   \text{if } k = 1 \text{ and } \text{ib_SIheff} < \text{thkR}, \quad \text{thkR} = \text{thkR} - \text{ib_SIheff}

If :math:`\text{thkR} \le 0`, the model stops.

In this case, drag is calculated as a combination of:
- **Form drag** on the vertical sides
- **Skin drag** on the horizontal bottom

The x and y component drag forces become:

.. math::

   \text{ib_FwU_z}(k) = 0.5 \cdot \rho_w \cdot \left(
       C_{wv} \cdot \text{ib_perpL} \cdot \text{ib_keel} \cdot \text{thkR}
       + C_{wh} \cdot \text{ib_wth} \cdot \text{ib_keel} \cdot \text{ib_lth} \cdot \text{ib_keel}
   \right) \cdot V_r \cdot u_r

Where:

- :math:`\rho_w` is water density
- :math:`C_{wv}` and :math:`C_{wh}` are vertical and horizontal drag coefficients
- :math:`V_r` is the relative velocity magnitude between water and iceberg
- :math:`u_r` and :math:`v_r` are the relative velocity components in x and y
- :math:`\text{ib_perpL}`, :math:`\text{ib_wth}`, and :math:`\text{ib_lth}` are iceberg geometry terms

Air Drag Force
----------------

To calculate Air Drag force, there are 3 options:

- Use keel model (:ref:`Iceberg Keel Model`)
- Use sail model (:ref:`Sail Model`)
- Use tabular model (``ib_keel=1``)

**Note:** In the first run, iceberg mass is updated using

.. math::

   ib\_mass = ib\_mass
   + \left(
       ib\_wth(ib_n)
       \cdot ib\_keel
       \cdot ib\_lth(ib_n)
       \cdot ib\_keel
       \cdot ib\_fbd(ib_n)
       \cdot 0.5
       \cdot ib\_rho
     \right)

Using Keel Model
~~~~~~~~~~~~~~~~~

Reduce length of ib_perpL to be consistent with keel model
and icebergs having their maximum length below the waterline.
We use the polynomial fit to the Barker et al (2004) keel data
and assume a two layer model for the portion of the
iceberg ABOVE water. The top (bottom) layers have lengths
61% (78%) of the maximum length below the water line.

.. math::

   ib\_Fa = ib\_Fa
   + \left(
       0.5 \cdot \rho_a
       \cdot C_{av}
       \cdot ib\_perpL
       \cdot ib\_keel
       \cdot ib\_fbd(ib_n)
       \cdot 0.5
       \cdot Vel_{a_r}
       \cdot uvel_{a_r}
     \right)

**Note:** Only applied to icebergs with length > 50m, based on CIS model (Kubat et al., 2005)


.. _Sail Model:

Using Sail Model
~~~~~~~~~~~~~~~~~

Option to estimate air drag using empirical Sail Area model
based on Canadian Hydraulics Centre (CHC) iceberg model (Barker et al 2004)
Icebergs have a pinnacle shape typical of those observed at the Grand Banks.
Using this scheme reduces wind drag on an iceberg.

.. math::
    Sail area = A_o * L + B_o

where Ao = 28.194 m and Bo = -1420.2 m2 based on constants from
Barker et al. 2004).

.. math::

   ib\_Fa = 0.5 \cdot \rho_a \cdot Cav \cdot sail\_area\ \cdot Vel\_a\_r \cdot vel\_a\_r

Using

**Note:** If sail area is less than Zero (at approx. lengths of 50 m) then air drag is ignored.

Using Tabular Icebergs
~~~~~~~~~~~~~~~~~~~~~~~

.. math::

   ib\_Fa = 0.5 \cdot \rho_a \cdot
             \left( Cav \cdot ib\_perpL \cdot ib\_fbd(ib\_n)
             + Cah \cdot ib\_wth(ib\_n) \cdot ib\_lth(ib\_n) \right)
             \cdot Vel\_a\_r \cdot vel\_a\_r

Wave Radiation Force
---------------------

.. math::

   Fr = \frac{1}{2} \cdot \rho_W \cdot Cr \cdot g \cdot \min(Wamp, ib\_fbd)^2 \cdot Lw \cdot \frac{vel_a}{|vel_a|}

Where:

- :math:`Cr` is the wave coefficient
- :math:`g` is gravitational acceleration
- :math:`Wamp` is wave amplitude
- :math:`ib\_fbd` is iceberg freeboard height
- :math:`Lw` is iceberg length normal to incident wave direction
- :math:`vel_a` is air velocity

Notes:

- Equation modified from Savage et al. (2001) to include dependence of wave height on sea ice.
- Wave direction is assumed to be the same as air velocity.
- Wave height (Wh) is given by:

.. math::

 Wh = 0.02025 \cdot |vel_a - vel_w|^2

Based on the quadratic fit of wave height to wind speed from the marine Beaufort Scale (Bigg et al. 1997).

- Example: a 30 ms\ :sup:`-1` wind produces ~9 m wave height and amplitude of 4.5 m.
- As with Martin and Adcroft (2010), only wind speed relative to ocean is considered.
- Increased sea ice area dampens wave drag influence, similar to wave erosion treatment in ``iceberg_therm.F``.
- If wave height > freeboard height, freeboard height is used to avoid unrealistic forces on small icebergs (Modified from Martin and Adcroft, 2010).
- Variable wave coefficient (:math:`Cr`) dampens wave radiation when iceberg length to wavelength ratio is small, preventing dominance of wave radiation force (Martin and Adcroft, 2010; Carrieres et al. 2001). Typical :math:`Cr` is ~0.06, decreasing below 0.06 for ib_lth/Lw < 0.25 (Carrieres et al. Fig. 6).

The value of wave radiation force is calculated using:

.. math::

   ib\_Fr = 0.5 \cdot \rho_w \cdot Cr \cdot gravity
             \cdot Wh^2 \cdot ib\_perpL
             \cdot \frac{vel_a}{|vel_a|}

SEA ICE DRAG
-------------

N.B  ``SIarea`` <0.15 does not exert force on the iceberg
((Lichey and Hellmer, 2001) as it is assumed to open water. This is
acheived by setting ``SIheff = 0`` when ``SIarea < 0.15``. This criteria is set i
earlier when Sea ice fields are loaded. Also, when ``SIarea > 0.9``
like (Lichey and Hellmer, 2001) we assume that all other forcings
are set to zero and that icebergs are 'locked' in the sea ice
and drift with the pack ice.

.. math::

   uvel\_si\_r = uvel\_si - ib\_uVel(ib\_n)

.. math::

   vvel\_si\_r = vvel\_si - ib\_vVel(ib\_n)

.. math::

   Vel\_si\_r = \left| \sqrt{ uvel\_si\_r^2 + vvel\_si\_r^2 } \right|

If :math:`ib\_SIheff > ib\_fbd(ib\_n)` then :math:`ib\_SIheff = ib\_fbd(ib\_n)`

.. math::

   ib\_Fi = 0.5 \cdot \rho\_si \cdot Civ
            \cdot ( ib\_perpL \cdot ib\_SIheff )
            \cdot Vel\_si\_r^2

Consider mass added to the iceberg due to the water that the iceberg
drags along with it, as used in the Canadian Hydraulics Center iceberg model
(Kubat et al. 2005).

.. math::

    ib_\text{mass} = ib_\text{mass} * 1.5

Explanation:

- On the first timestep (:math:`ib\_tstep = 1`), the iceberg mass is increased by a factor of 1.5 to account for the added mass effect from the surrounding water that is dragged along as the iceberg accelerates.

Coriolis Force
--------------

The Coriolis force is calculated based on the hemisphere in which the iceberg is located:

- If the latitude (:math:`ib\_lat`) is greater than or equal to zero (Northern Hemisphere), set `hemis = -1.0`, resulting in deflection to the right.
- Otherwise (Southern Hemisphere), set `hemis = 1.0`, resulting in deflection to the left.

The Coriolis force components are then calculated as:

.. math::

   ib\_FcU = ib\_mass \cdot ib\_cori \cdot ib\_vVel(ib\_n)

.. math::

   ib\_FcV = ib\_mass \cdot ib\_cori \cdot ib\_uVel(ib\_n) \cdot hemis

Pressure Gradient Force
------------------------

.. math::
    F_p = -M \cdot g \cdot grad

where :math:`grad` is the sea surface sloop from the free surface model

.. math::
    grad_u = (etaN(i1,j1,bi,bj) - etaN(i1+1,j1,bi,bj)) / dxg(i1,j1,bi,bj)

.. math::
    grad_v = (etaN(i1,j1,bi,bj) - etaN(i1,j1+1,bi,bj)) / dyg(i1,j1,bi,bj)

**Note:** The PGF causes icebergs to move down slope.
The minus sign is excluded in the equation below because
gravity has a positive sign in the model.

Sum Forces Acting On Iceberg
-----------------------------

The total force acting on the iceberg is calculated:

.. math::
    ib_F =   ib_Fw + ib_Fa + ib_Fr + ib_Fi + ib_Fp + ib_Fc

**Note:** if ``USE_LAGRANGIAN_FLOAT`` is **ENABLED** in ``data.iceberg``, :math:`ib_F = ib_Fw` only.

Convert Force To Acceleration
------------------------------

The total force calculated above is measured by :math:`kg \cdot m \cdot s-2`. Hence we need to convert it to acceleration
for calculating advection by :math:`ib_F = ib_F/ib_mass`

Iceberg Advection
------------------

Once obtained all the forces, the advection is calculated as proposed in :ref:`Advection Framework`

However, the distance traveled may be different in some scenarios:

- If the iceberg is small (``thickness < 3`` OR ``width < 3``), then it will drift with the ocean:

If ``ALLOW_ICEBERG_MULTILEVEL`` is **ENABLED** in ``data.iceberg``

.. math::
    ib_\text{uVel}(ib_n) =  uvel_w(1)
.. math::
    ib_\text{vVel}(ib_n) =  vvel_w(1)

else

.. math::
    ib_\text{uVel}(ib_n) =  uvel_w
.. math::
    ib_\text{vVel}(ib_n) =  vvel_w

- If ``ALLOW_SEAICE`` and ``ICEBERGS_DRIFT_WITH_SEAICE`` are **BOTH ENABLED** in ``data.iceberg``, then if iceberg in thick sea ice (``SIarea >= 0.9``):

.. math::
    ib_\text{uVel}(ib_n) = uvel_si

.. math::
    ib_\text{vVel}(ib_n) = vvel_si

- If ``CAP_ICEBERG_VELOCITY`` is **ENABLED** in ``data.iceberg``, then the iceberg velocity set to ocean velocity

Move Iceberg On Model Grid
----------------------------

.. math::
    ib_\text{i}(ib_n) = ib_\text{i}(ib_n)  + dist_i
.. math::
    ib_\text{j}(ib_n) = ib_\text{j}(ib_n)  + dist_j

**Note:** The icebergs at the edge of model grid are flagged as melted