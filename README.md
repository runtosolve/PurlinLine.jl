# PurlinLine.jl

**PurlinLine.jl** is an open-source Julia package that predicts the structural response and capacity of a purlin or girt line in a metal building under gravity or wind uplift cladding pressure. It implements the computation-based design method described in AISI S100-16 Section I6.1.

Developed by [Cristopher D. Moen, Ph.D., P.E.](mailto:cris.moen@runtosolve.com) at [RunToSolve, LLC](https://runtosolve.com).

---

## What it does

Given a description of the purlin line geometry, cross-sections, material properties, and cladding, PurlinLine.jl:

- Calculates cladding bracing stiffnesses from derived equations and data-driven interpolation models
- Computes local and distortional buckling strengths with CUFSM and AISI S100-16 equations
- Performs a second-order thin-walled beam analysis that accounts for load eccentricity, lateral-torsional buckling deformation, cladding bracing stiffness, and warping torsion
- Models free-flange deformation from torsion shear flow with a second-order thin-walled beam-column analysis
- Checks AISI S100-16 interaction equations (flexure+shear, biaxial bending, flexure+torsion) at every cross-section along the line
- Loads the purlin line to failure and identifies the governing limit state and failure location

Supported design codes: `"AISI S100-16 ASD"`, `"AISI S100-16 LRFD"`, `"AISI S100-16 LFD"`, `"AISI S100-16 nominal"`.

---

## Installation

PurlinLine.jl requires Julia 1.6.1 or later. Install from the Julia REPL:

```julia
using Pkg
Pkg.add(url = "https://github.com/runtosolve/PurlinLine.jl.git")
```

Or, to develop from a local clone:

```julia
Pkg.develop(path = "/path/to/PurlinLine")
```

---

## Quick start

### Simple span — uplift

Units are kips and inches throughout.

```julia
using PurlinLine

loading_direction = "uplift"
design_code       = "AISI S100-16 ASD"

#            length      dL   section  material
segments = [(25.0 * 12, 25.0,  1,       1)]

spacing   = 60.0     # purlin spacing, in.
roof_slope = 0.0     # degrees

# Z-section: (type, t, b_lip_bot, b_flange_bot, h_web, b_flange_top, b_lip_top,
#             θ_lip_bot, θ_flange_bot, θ_web, θ_flange_top, θ_lip_top,
#             r_bot_lip, r_bot_flange, r_top_flange, r_top_lip)
cross_section_dimensions = [
    ("Z", 0.059, 0.91, 2.5, 8.0, 2.5, 0.91,
     -55.0, 0.0, 90.0, 0.0, -55.0,
     3*0.059, 3*0.059, 3*0.059, 3*0.059)
]

#                    E        ν     Fy    Fu
material_properties = [(29500.0, 0.30, 55.0, 70.0)]

# Screw-fastened cladding: (type, t_deck, fastener_spacing, d_screw, Fss)
deck_details           = ("screw-fastened", 0.0179, 12.0, 0.212, 2.50)
deck_material_properties = (29500.0, 0.30, 55.0, 70.0)

frame_flange_width   = 16.0
support_locations    = [0.0, 25.0 * 12]
purlin_frame_connections = "bottom flange connection"
bridging_locations   = []

# Assemble inputs and build the model
inputs = PurlinLine.Inputs(
    loading_direction, design_code, segments, spacing, roof_slope,
    cross_section_dimensions, material_properties,
    deck_details, deck_material_properties,
    frame_flange_width, support_locations,
    purlin_frame_connections, bridging_locations
)

purlin_line = PurlinLine.build(inputs)

# Load to failure
purlin_line = PurlinLine.test(purlin_line)

# Key results
failure_pressure_psf   = purlin_line.applied_pressure * 1000 * 144
failure_limit_state    = purlin_line.failure_limit_state
failure_location_in    = purlin_line.failure_location
```

---

### Four-span continuous purlin line — gravity

```julia
using PurlinLine

loading_direction = "gravity"
design_code       = "AISI S100-16 nominal"

#              length       dL   section  material
segments = [
    (23.0*12, 12.0,  2,  1),   # end span
    ( 2.0*12, 12.0,  3,  1),   # lap splice
    ( 2.0*12, 12.0,  3,  1),
    (21.0*12, 12.0,  1,  1),   # interior span
    ( 2.0*12, 12.0,  3,  1),
    ( 2.0*12, 12.0,  3,  1),
    (21.0*12, 12.0,  1,  1),
    ( 2.0*12, 12.0,  3,  1),
    ( 2.0*12, 12.0,  3,  1),
    (23.0*12, 12.0,  2,  1),
]

spacing    = 60.0
roof_slope = rad2deg(atan(1 / 12))   # 1:12 slope

cross_section_dimensions = [
    ("Z", 0.059, 0.91, 2.5, 8.0, 2.5, 0.91, -50.0, 0.0, 90.0, 0.0, -50.0,
     3*0.059, 3*0.059, 3*0.059, 3*0.059),   # interior span section
    ("Z", 0.068, 0.91, 2.5, 8.0, 2.5, 0.91, -50.0, 0.0, 90.0, 0.0, -50.0,
     3*0.068, 3*0.068, 3*0.068, 3*0.068),   # end span (heavier gauge)
    ("Z", 0.118, 0.91, 2.5, 8.0, 2.5, 0.91, -50.0, 0.0, 90.0, 0.0, -50.0,
     3*0.059, 3*0.059, 3*0.059, 3*0.059),   # double thickness at lap
]

material_properties      = [(29500.0, 0.30, 55.0, 70.0)]
deck_details             = ("screw-fastened", 0.0179, 12.0, 0.212, 2.50)
deck_material_properties = (29500.0, 0.30, 55.0, 70.0)
frame_flange_width       = 16.0
support_locations        = [0.0, 25.0*12, 50.0*12, 75.0*12, 100.0*12]
purlin_frame_connections = "bottom flange connection"
bridging_locations       = []

inputs = PurlinLine.Inputs(
    loading_direction, design_code, segments, spacing, roof_slope,
    cross_section_dimensions, material_properties,
    deck_details, deck_material_properties,
    frame_flange_width, support_locations,
    purlin_frame_connections, bridging_locations
)

purlin_line = PurlinLine.build(inputs)
purlin_line = PurlinLine.test(purlin_line)

println("Failure pressure: ", round(purlin_line.applied_pressure * 1000 * 144, digits=1), " psf")
println("Limit state: ",       purlin_line.failure_limit_state)
println("Failure location: ",  purlin_line.failure_location, " in.")
```

---

## Inputs

| Argument | Type | Description |
|---|---|---|
| `loading_direction` | `String` | `"gravity"` or `"uplift"` |
| `design_code` | `String` | `"AISI S100-16 ASD"`, `"LRFD"`, `"LFD"`, or `"nominal"` |
| `segments` | `Vector{Tuple}` | `(length_in, dL_in, section_index, material_index)` for each segment |
| `spacing` | `Float64` | Purlin bay spacing, in. |
| `roof_slope` | `Float64` | Roof slope, degrees |
| `cross_section_dimensions` | `Vector{Tuple}` | One tuple per unique section; see format below |
| `material_properties` | `Vector{NTuple{4}}` | `(E, ν, Fy, Fu)` per material |
| `deck_details` | `Tuple` | `("screw-fastened", t, s_f, d_screw, Fss)` or `("vertical leg standing seam", clip_spacing)` |
| `deck_material_properties` | `NTuple{4}` | `(E, ν, Fy, Fu)` for deck |
| `frame_flange_width` | `Float64` | Primary frame flange width, in. (used for web crippling check) |
| `support_locations` | `Vector{Float64}` | Distances from left end to each primary frame support, in. |
| `purlin_frame_connections` | `String` | `"bottom flange connection"` or `"anti-roll clip"` |
| `bridging_locations` | `Vector{Float64}` | Distances from left end to intermediate bridging/bracing points, in. |

**Cross-section tuple format** (out-to-out dimensions):

```
("Z" or "C",  t,  b_lip_bot,  b_flange_bot,  h_web,  b_flange_top,  b_lip_top,
 θ_lip_bot,  θ_flange_bot,  θ_web,  θ_flange_top,  θ_lip_top,
 r_bot_lip,  r_bot_flange,  r_top_flange,  r_top_lip)
```

For a Zee section `CorZ = 0`; for a Cee section `CorZ = 1`. Flange angles are measured from horizontal; lip angles from the adjoining flange. All dimensions in inches, angles in degrees.

---

## Outputs

After `PurlinLine.test`, the result struct exposes:

| Field | Description |
|---|---|
| `applied_pressure` | Failure pressure, kips/in² |
| `failure_limit_state` | Governing limit state string |
| `failure_location` | Distance from left end at failure, in. |
| `internal_forces` | `Mxx`, `Myy`, `Vyy`, `T`, `B` along the line |
| `model.v`, `model.ϕ` | Vertical deflection and twist along the line |
| `free_flange_model.u` | Free-flange lateral displacement |
| `expected_strengths` | `eMnℓ_xx`, `eMnd_xx`, `eVn`, `eBn`, etc. |
| `flexure_torsion_demand_to_capacity` | D/C ratios and interaction values |
| `flexure_shear_demand_to_capacity` | D/C array |
| `distortional_demand_to_capacity` | D/C array |
| `local_buckling_xx_pos[i].CUFSM_data` | CUFSM model for local buckling (signature curve, mode shapes) |

### Plotting results

```julia
using Plots

z = purlin_line.model.inputs.z

plot(z, purlin_line.internal_forces.Mxx, ylabel = "Moment (kip·in)", legend = false)
plot(z, purlin_line.model.v,             ylabel = "Vertical deflection (in)", legend = false)
plot(z, purlin_line.model.ϕ,             ylabel = "Twist (rad)", legend = false)
plot(z, purlin_line.flexure_torsion_demand_to_capacity.interaction, ylabel = "D/C", legend = false)
```

---

## Validation

Predicted purlin line strengths have been compared against 49 simple-span Cee and Zee wall girt uplift pressure box tests. The average test-to-predicted ratio is **1.06** with a coefficient of variation of **0.15**. The governing failure mode — combined strong-axis bending, weak-axis bending, torsion, and cross-sectional deformation of the free flange — was correctly identified in both tests and predictions.

See: Moen, C.D. (2020). *Metal Building Roof Purlin Line Strength by Computation.* Proceedings of the Cold-Formed Steel Research Consortium Colloquium.

---

## Dependencies

| Package | Role |
|---|---|
| [CUFSM.jl](https://github.com/runtosolve/CUFSM.jl) | Local and distortional elastic buckling (finite strip method) |
| [AISIS100.jl](https://github.com/runtosolve/AISIS100.jl) | AISI S100-16 strength equations |
| [ThinWalledBeam.jl](https://github.com/runtosolve/ThinWalledBeam.jl) | Second-order thin-walled beam analysis |
| [ThinWalledBeamColumn.jl](https://github.com/runtosolve/ThinWalledBeamColumn.jl) | Free-flange beam-column analysis |
| [ScrewConnections.jl](https://github.com/runtosolve/ScrewConnections.jl) | Cladding translational and rotational stiffness |
| [SectionProperties.jl](https://github.com/runtosolve/SectionProperties.jl) | Cross-section geometry and properties |
| [CrossSectionGeometry.jl](https://github.com/runtosolve/CrossSectionGeometry.jl) | Section discretization |
| [InternalForces.jl](https://github.com/runtosolve/InternalForces.jl) | Internal force recovery |

---

## License

See [license.md](license.md).
