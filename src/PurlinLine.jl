module PurlinLine

using Base: String, Float64
using StructuresKit

using NumericalIntegration

export build, analyze, test


struct Inputs

    design_code::String
    segments::Vector{Tuple{Float64, Int64, Int64}}
    spacing::Float64
    roof_slope::Float64
    cross_section_dimensions::Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}
    material_properties::Vector{NTuple{4, Float64}}
    deck_details::Tuple{String, Float64, Float64, Float64, Float64}
    deck_material_properties::NTuple{4, Float64}
    frame_flange_width::Float64
    support_locations::Vector{Float64}
    purlin_frame_connections::String
    bridging_locations::Vector{Float64}
  

end



Base.@kwdef struct CrossSectionData

    n::Array{Int64}
    n_radius::Array{Int64}
    node_geometry::Array{Float64}
    element_definitions::Array{Float64}
    section_properties::CUFSM.SectionProperties
    plastic_section_properties::Union{StructuresKit.CrossSection.PlasticSectionProperties, Nothing} = nothing

end

struct BracingData

       kp::Float64
       kϕ::Float64
       kϕ_dist::Float64 
       kx::Float64 
       Lcrd::Float64
       Lm::Float64

end

struct FreeFlangeData

    kxf::Float64
    kϕf::Float64
    kH::Float64

end


struct ElasticBucklingData

    CUFSM_data::CUFSM.data
    Lcr::Float64
    Mcr::Float64

end

struct YieldingFlexuralStrengthData

    S_pos::Float64
    S_neg::Float64
    My_pos::Float64
    My_neg::Float64
    My::Float64
    eMy::Float64

end


struct LocalGlobalFlexuralStrengthData

    Mne::Float64
    Mnℓ_pos::Float64
    Mnℓ_neg::Float64
    eMnℓ_pos::Float64
    eMnℓ_neg::Float64
 
end

struct DistortionalFlexuralStrengthData

    Mnd_pos::Float64
    Mnd_neg::Float64
    eMnd_pos::Float64
    eMnd_neg::Float64
 
end

struct TorsionStrengthData

    Wn::Float64
    Bn::Float64
    eBn::Float64

end

struct ShearStrengthData

    h_flat::Float64
    Fcrv::Float64
    kv::Float64
    Vcr::Float64
    Vn::Float64
    eVn::Float64

end

struct WebCripplingData

    support_condition::String
    flange_condition::String
    load_case::String
    load_location::String
    C::Float64 
    C_R::Float64
    R::Float64 
    C_N::Float64 
    N::Float64
    C_h::Float64 
    ϕ_w::Float64 
    Ω_w::Float64 
    Pn::Float64
    ePn::Float64

end

struct FlexureTorsion_DemandToCapacity_Data
    
    action_Mxx::Array{Float64}
    action_Myy::Array{Float64}
    action_B::Array{Float64}
    action_Myy_freeflange::Array{Float64}
    interaction::Array{Float64}
    demand_to_capacity::Array{Float64}

end

struct BiaxialBending_DemandToCapacity_Data
    
    action_P::Array{Float64}
    action_Mxx::Array{Float64}
    action_Myy::Array{Float64}
    interaction::Array{Float64}
    demand_to_capacity::Array{Float64}

end


struct InternalForceData

    P::Array{Float64}
    Mxx::Array{Float64}
    Myy::Array{Float64}
    Vxx::Array{Float64}
    Vyy::Array{Float64}
    T::Array{Float64}
    B::Array{Float64}

end

struct Reactions

    Fyy::Array{Float64}

end

struct ExpectedStrengths

    eMnℓ_xx::Array{Float64}
    eMnℓ_yy::Array{Float64}
    eMnℓ_yy_free_flange::Array{Float64}
    eMnd_xx::Array{Float64}
    eVn::Array{Float64}
    eBn::Array{Float64}

end



mutable struct PurlinLineObject

    inputs::PurlinLine.Inputs

    applied_pressure::Float64

    loading_direction::String

    cross_section_data::Array{PurlinLine.CrossSectionData}
    free_flange_cross_section_data::Array{PurlinLine.CrossSectionData}

    bracing_data::Array{PurlinLine.BracingData}

    free_flange_data::Array{PurlinLine.FreeFlangeData}

    local_buckling_xx_pos::Array{PurlinLine.ElasticBucklingData}
    local_buckling_xx_neg::Array{PurlinLine.ElasticBucklingData}
    local_buckling_yy_pos::Array{PurlinLine.ElasticBucklingData}
    local_buckling_yy_neg::Array{PurlinLine.ElasticBucklingData}
    distortional_buckling_xx_pos::Array{PurlinLine.ElasticBucklingData}
    distortional_buckling_xx_neg::Array{PurlinLine.ElasticBucklingData}

    yielding_flexural_strength_xx::Array{PurlinLine.YieldingFlexuralStrengthData}
    yielding_flexural_strength_yy::Array{PurlinLine.YieldingFlexuralStrengthData}
    yielding_flexural_strength_free_flange_yy::Array{PurlinLine.YieldingFlexuralStrengthData}

    local_global_flexural_strength_xx::Array{PurlinLine.LocalGlobalFlexuralStrengthData}
    local_global_flexural_strength_yy::Array{PurlinLine.LocalGlobalFlexuralStrengthData}
    local_global_flexural_strength_free_flange_yy::Array{PurlinLine.LocalGlobalFlexuralStrengthData}

    distortional_flexural_strength_xx::Array{PurlinLine.DistortionalFlexuralStrengthData}

    torsion_strength::Array{PurlinLine.TorsionStrengthData}

    shear_strength::Array{PurlinLine.ShearStrengthData}

    web_crippling::Array{PurlinLine.WebCripplingData}

    model::ThinWalledBeam.Model

    free_flange_model::BeamColumn.Model

    internal_forces::InternalForceData

    free_flange_internal_forces::InternalForceData

    support_reactions::Reactions

    flexure_torsion_demand_to_capacity::FlexureTorsion_DemandToCapacity_Data
    biaxial_bending_demand_to_capacity::BiaxialBending_DemandToCapacity_Data
    distortional_demand_to_capacity::Array{Float64}
    flexure_shear_demand_to_capacity::Array{Float64}
    web_crippling_demand_to_capacity::Array{Float64}

    expected_strengths::ExpectedStrengths

    failure_limit_state::String

    failure_location::Float64

    PurlinLineObject() = new()

end


function define_purlin_cross_section(cross_section_type, t, d1, b1, h, b2, d2, α1, α2, α3, α4, α5, r1, r2, r3, r4, n, n_radius)

    if cross_section_type == "Z"

        #Define the top Z purlin surface.   For the top flange, this means the out-to-out dimensions.  For the bottom flange, the interior outside dimensions should be used.

        #First calculate the correction on out-to-out length to go from the outside surface to the inside bottom flange surface.
        delta_lip_bottom = t / tan((π - deg2rad(abs(α2 - α1))) / 2)
        delta_web_bottom = t / tan((π - deg2rad(abs(α3 - α2))) / 2)

        #Note here that the bottom flange and lip dimensions are smaller here.
        ΔL = [d1 - delta_lip_bottom, b1 - delta_lip_bottom - delta_web_bottom, h - delta_web_bottom, b2, d2]
        θ = [α1, α2, α3, α4, α5]

        #Note that the outside radius is used at the top flange, and the inside radius is used for the bottom flange.
        radius = [r1 - t, r2 - t, r3, r4]

        closed_or_open = 1

        purlin = CrossSection.Feature(ΔL, θ, n, radius, n_radius, closed_or_open)

        #Calculate the out-to-out purlin surface coordinates.
        xcoords_out, ycoords_out = CrossSection.get_xy_coordinates(purlin)

        #Calculate centerline purlin coordinates.
        unitnormals = CrossSection.surface_normals(xcoords_out, ycoords_out, closed_or_open)
        nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
        xcoords_center, ycoords_center = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, -t/2)

        #Shift y coordinates so that the bottom purlin face is at y = 0.
        ycoords_center = ycoords_center .- minimum(ycoords_center) .+ t/2

        #Shift x coordinates so that the purlin web centerline is at x = 0.
        index = floor(Int, length(xcoords_center)/2)
        xcoords_center = xcoords_center .- xcoords_center[index]

    elseif cross_section_type == "C"

        r1 = r1 - t #outside to inside
        r2 = r1 - t
        r3 = r1 - t
        r4 = r1 - t
        nh = n[3]
        nb1 = n[2]
        nb2 = n[4]
        nd1 = n[1]
        nd2 = n[5]
        nr1 = n_radius[1]
        nr2 = n_radius[2]
        nr3 = n_radius[3]
        nr4 = n_radius[4]

        kipin = 1
        CorZ = 1
        center = 2  #out to out

        q1 = 90.0
        q2 = 90.0

        prop,node,elem,lengths,springs,constraints,geom,cz = StructuresKit.CUFSM.templatecalc(CorZ,h,b1,b2,d1,d2,r1,r2,r3,r4,q1,q2,t,nh,nb1,nb2,nd1,nd2,nr1,nr2,nr3,nr4,kipin,center)

        xcoords_center = node[:, 2]
        ycoords_center = node[:, 3]

        #Shift y coordinates so that the bottom purlin face is at y = 0.
        ycoords_center = ycoords_center .- minimum(ycoords_center) .+ t/2

        #Shift x coordinates so that the purlin web centerline is at x = 0.
        index = floor(Int, length(xcoords_center)/2)
        xcoords_center = xcoords_center .- xcoords_center[index]

    end

    #Package nodal geometry.
    node_geometry = [xcoords_center ycoords_center]

    #Define cross-section element connectivity and thicknesses.
    num_cross_section_nodes = length(xcoords_center)
    element_info = [1:(num_cross_section_nodes - 1) 2:num_cross_section_nodes ones(num_cross_section_nodes - 1) * t]

    return node_geometry, element_info

end



function define_purlin_free_flange_cross_section(cross_section_type, t, d1, b1, h, α1, α2, α3, r1, r2, n, n_radius)

    if cross_section_type == "Z"

        #Define the top Z purlin surface.   For the top flange, this means the out-to-out dimensions.  For the bottom flange, the interior outside dimensions should be used.

        #First calculate the correction on out-to-out length to go from the outside surface to the inside bottom flange surface.
        delta_lip_bottom = t / tan((π - deg2rad(abs(α2 - α1))) / 2)
        delta_web_bottom = t / tan((π - deg2rad(abs(α3 - α2))) / 2)

        #Note here that the bottom flange and lip dimensions are smaller here.
        #Use 1/5 of the web height.
        ΔL = [d1 - delta_lip_bottom, b1 - delta_lip_bottom - delta_web_bottom, h/5 - delta_web_bottom]
        θ = [α1, α2, α3]

        #The inside radius is used for the bottom flange.
        radius = [r1 - t, r2 - t]

        closed_or_open = 1

        purlin = CrossSection.Feature(ΔL, θ, n, radius, n_radius, closed_or_open)

        #Calculate the out-to-out purlin surface coordinates.
        xcoords_out, ycoords_out = CrossSection.get_xy_coordinates(purlin)

        #Calculate centerline purlin coordinates.
        unitnormals = CrossSection.surface_normals(xcoords_out, ycoords_out, closed_or_open)
        nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
        xcoords_center, ycoords_center = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, -t/2)

        #Shift y coordinates so that the bottom purlin face is at y = 0.
        ycoords_center = ycoords_center .- minimum(ycoords_center) .+ t/2

        #Shift x coordinates so that the purlin web centerline is at x = 0.
        index = length(xcoords_center)
        xcoords_center = xcoords_center .- xcoords_center[index]

    elseif cross_section_type == "C"

        #Define the top C purlin surface.   For the top flange, this means the out-to-out dimensions.  For the bottom flange, the interior outside dimensions should be used.

        #First calculate the correction on out-to-out length to go from the outside surface to the inside bottom flange surface.
        delta_lip_bottom = t / tan((π - deg2rad(abs(α2 - α1))) / 2)
        delta_web_bottom = t / tan((π - deg2rad(abs(α3 - α2))) / 2)

        #Note here that the bottom flange and lip dimensions are smaller here.
        #Use 1/5 of the web height.
        ΔL = [d1 - delta_lip_bottom, b1 - delta_lip_bottom - delta_web_bottom, h/5 - delta_web_bottom]
        θ = [α1, α2, α3]

        #The inside radius is used for the bottom flange.
        radius = [r1 - t, r2 - t]

        closed_or_open = 1

        purlin = CrossSection.Feature(ΔL, θ, n, radius, n_radius, closed_or_open)

        #Calculate the out-to-out purlin surface coordinates.
        xcoords_out, ycoords_out = CrossSection.get_xy_coordinates(purlin)

        #Calculate centerline purlin coordinates.
        unitnormals = CrossSection.surface_normals(xcoords_out, ycoords_out, closed_or_open)
        nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
        xcoords_center, ycoords_center = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, -t/2)

        #Shift y coordinates so that the bottom purlin face is at y = 0.
        ycoords_center = ycoords_center .- minimum(ycoords_center) .+ t/2

        #Shift x coordinates so that the purlin web centerline is at x = 0.
        index = length(xcoords_center)
        xcoords_center = xcoords_center .- xcoords_center[index]

    end

    #Package nodal geometry.
    node_geometry = [xcoords_center ycoords_center]

    #Define cross-section element connectivity and thicknesses.
    num_cross_section_nodes = length(xcoords_center)
    element_info = [1:(num_cross_section_nodes - 1) 2:num_cross_section_nodes ones(num_cross_section_nodes - 1) * t]

    return node_geometry, element_info

end


function define_purlin_section(cross_section_dimensions, n, n_radius)

    num_purlin_sections = size(cross_section_dimensions)[1]

    cross_section_data = Vector{CrossSectionData}(undef, num_purlin_sections)

    for i=1:num_purlin_sections

        cross_section_type = cross_section_dimensions[i][1]
        t = cross_section_dimensions[i][2]
        d1 = cross_section_dimensions[i][3]
        b1 = cross_section_dimensions[i][4]
        h = cross_section_dimensions[i][5]
        b2 = cross_section_dimensions[i][6]
        d2 = cross_section_dimensions[i][7]
        α1 = cross_section_dimensions[i][8]
        α2 = cross_section_dimensions[i][9]
        α3 = cross_section_dimensions[i][10]
        α4 = cross_section_dimensions[i][11]
        α5 = cross_section_dimensions[i][12]
        r1 = cross_section_dimensions[i][13]
        r2 = cross_section_dimensions[i][14]
        r3 = cross_section_dimensions[i][15]
        r4 = cross_section_dimensions[i][16]

        #Define the purlin cross-section nodes and elements.
        purlin_node_geometry, purlin_element_info = define_purlin_cross_section(cross_section_type, t, d1, b1, h, b2, d2, α1, α2, α3, α4, α5, r1, r2, r3, r4, n, n_radius)

        #Calculate the purlin elastic cross-section properties.
        purlin_section_properties = CUFSM.cutwp_prop2(purlin_node_geometry, purlin_element_info)

        #Calculate purlin plastic neutral axis and plastic modulus.
        n_plastic = n .* 10   #Use a fine discretization to find the plastic section properties.
        purlin_plastic_node_geometry, purlin_plastic_element_info = define_purlin_cross_section(cross_section_type, t, d1, b1, h, b2, d2, α1, α2, α3, α4, α5, r1, r2, r3, r4, n_plastic, n_radius)

        about_axis = "x"  #The strong axis plastic properties are needed for now.  
        purlin_plastic_section_properties = StructuresKit.CrossSection.calculate_plastic_section_properties(purlin_plastic_node_geometry, purlin_plastic_element_info, about_axis)

        cross_section_data[i] = CrossSectionData(n, n_radius, purlin_node_geometry, purlin_element_info, purlin_section_properties, purlin_plastic_section_properties)
       
    end

    return cross_section_data

end


function define_purlin_free_flange_section(cross_section_dimensions, n, n_radius)

    num_purlin_sections = size(cross_section_dimensions)[1]

    free_flange_cross_section_data = Vector{CrossSectionData}(undef, num_purlin_sections)

    for i=1:num_purlin_sections

        cross_section_type = cross_section_dimensions[i][1]
        t = cross_section_dimensions[i][2]
        d1 = cross_section_dimensions[i][3]
        b1 = cross_section_dimensions[i][4]
        h = cross_section_dimensions[i][5]
        b2 = cross_section_dimensions[i][6]
        d2 = cross_section_dimensions[i][7]
        α1 = cross_section_dimensions[i][8]
        α2 = cross_section_dimensions[i][9]
        α3 = cross_section_dimensions[i][10]
        α4 = cross_section_dimensions[i][11]
        α5 = cross_section_dimensions[i][12]
        r1 = cross_section_dimensions[i][13]
        r2 = cross_section_dimensions[i][14]
        r3 = cross_section_dimensions[i][15]
        r4 = cross_section_dimensions[i][16]

        #Define the purlin free flange cross-section nodes and elements.
        purlin_free_flange_node_geometry, purlin_free_flange_element_info = define_purlin_free_flange_cross_section(cross_section_type, t, d1, b1, h, α1, α2, α3, r1, r2, n, n_radius)

        #Calculate the purlin free flange cross-section properties.
        purlin_free_flange_section_properties = CUFSM.cutwp_prop2(purlin_free_flange_node_geometry, purlin_free_flange_element_info)

        free_flange_cross_section_data[i] = CrossSectionData(n, n_radius, purlin_free_flange_node_geometry, purlin_free_flange_element_info, purlin_free_flange_section_properties, nothing)

    end

    return free_flange_cross_section_data

end

function deck_pull_through_fastener_stiffness(deck_material_properties, b_top, t_roof_deck)

    #Define the fastener distance from a major R-panel rib.  Hard coded for now.
    x = 25.4 #mm

    #Define the distance of the fastener from the flange pivot point.
    

    #Need this if statement to make sure units are treated propertly here.
    if deck_material_properties[1] == 203255.0

        #Define the fastener distance from the purlin pivot point.  The purlin pivot point for a Z section is the top flange - web intersection. Assume the fastener location is centered in the purlin top flange.
        c = b_top / 2 #mm

        #Define the roof deck thickness in metric.
        tw = t_roof_deck  #mm

        #Approximate the roof panel base metal thickness.
        kp = Connections.cfs_pull_through_plate_stiffness(x, c, tw)

    elseif deck_material_properties[1] == 29500.0

        #Define the fastener distance from the purlin pivot point.  The purlin pivot point for a Z section is the top flange - web intersection. Assume the fastener location is centered in the purlin top flange.
        c = b_top * 25.4 / 2 #mm

        #Define the roof deck thickness in metric.
        tw = t_roof_deck * 25.4  #mm

        #Approximate the roof panel base metal thickness.
        kp = Connections.cfs_pull_through_plate_stiffness(x, c, tw)

        #Convert kp from N/mm to kips/in.
        kp = kp / 1000 / 4.448 * 25.4

    else
        error("Set the deck elastic modulus to 29500.0 ksi or 203225.0 MPa.")

    end

    return kp

end


function define_deck_bracing_properties(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    bracing_data = Array{BracingData, 1}(undef, num_purlin_segments)

    if purlin_line.inputs.deck_details[1] == "screw-fastened"

        #Define the deck to purlin screw-fastened connection spacing.
        deck_purlin_fastener_spacing = purlin_line.inputs.deck_details[3]

        #Define the deck to purlin screw diameter.
        deck_purlin_fastener_diameter = purlin_line.inputs.deck_details[4]

        #Define the nominal shear strength of the typical screw.
        Fss = purlin_line.inputs.deck_details[5]

        #Define the roof deck base metal thickness.
        t_roof_deck = purlin_line.inputs.deck_details[2]

        #Define roof deck steel elastic modulus.
        E_roof_deck = purlin_line.inputs.deck_material_properties[1]

        #Define roof deck steel ultimate yield stress.
        Fu_roof_deck = purlin_line.inputs.deck_material_properties[4]

        #Define the distance between fasteners as the distortional discrete bracing length.
        Lm = deck_purlin_fastener_spacing

        #Loop over all the purlin segments in the line.
        for i = 1:num_purlin_segments

            #Define the section property index associated with purlin segment i.
            section_index = purlin_line.inputs.segments[i][2]

            #Define the material property index associated with purlin segment i.
            material_index = purlin_line.inputs.segments[i][3]

            #Define purlin steel elastic modulus.
            E_purlin = purlin_line.inputs.material_properties[material_index][1]

            #Define purlin steel Poisson's ratio.
            μ_purlin = purlin_line.inputs.material_properties[material_index][2]

            #Define purlin steel ultimate stress.
            Fu_purlin = purlin_line.inputs.material_properties[material_index][4]

            #Define the purlin top flange width.
            b_top = purlin_line.inputs.cross_section_dimensions[section_index][6]

            #Define purlin base metal thickness.
            t_purlin = purlin_line.inputs.cross_section_dimensions[section_index][2]

            #Define out-to-out purlin web depth.
            ho = purlin_line.inputs.cross_section_dimensions[section_index][5]

            #Define purlin top flange lip length.
            d_top = purlin_line.inputs.cross_section_dimensions[section_index][7]

            #Define purlin top flange lip angle from the horizon, in degrees.
            θ_top = purlin_line.inputs.cross_section_dimensions[section_index][11] - purlin_line.inputs.cross_section_dimensions[section_index][12]

            #Define the location from the purlin top flange pivot point to the fastener.  Assume the fastener is centered in the flange.
            c = b_top/2

            #Define the deck fastener pull-through plate stiffness.  Assume the fastener is centered between two panel ribs.
            kp = deck_pull_through_fastener_stiffness(purlin_line.inputs.deck_material_properties, b_top, t_roof_deck)

            #Apply Cee or Zee binary.
            if purlin_line.inputs.cross_section_dimensions[section_index][1] == "Z"
                CorZ = 1
            elseif purlin_line.inputs.cross_section_dimensions[section_index][1] == "C"
                CorZ = 0
            end

            #Calculate the rotational stiffness provided to the purlin by the screw-fastened connection between the deck and the purlin.  It is assumed that the deck flexural stiffness is much higher than the connection stiffness.
            kϕ = Connections.cfs_rot_screwfastened_k(b_top, c, deck_purlin_fastener_spacing, t_purlin, kp, E_purlin, CorZ)

            #Calculate the purlin distortional buckling half-wavelength.

            #Calculate top flange + lip section properties.
            Af, Jf, Ixf, Iyf, Ixyf, Cwf, xof,  hxf, hyf, yof = AISIS10016.table23131(CorZ, t_purlin, b_top, d_top, θ_top)

            #Calculate the purlin distortional buckling half-wavelength.
            Lcrd, L = AISIS10016.app23334(ho, μ_purlin, t_purlin, Ixf, xof, hxf, Cwf, Ixyf, Iyf, Lm)

            #If Lcrd is longer than the fastener spacing, then the distortional buckling will be restrained by the deck.
            if Lcrd >= Lm
                kϕ_dist = kϕ
            else
                kϕ_dist = 0.0
            end

            #Approximate the lateral stiffness provided to the top of the purlin by the screw-fastened connection between the deck and the purlin.

            #Calculate the stiffness of a single screw-fastened connection.
            Ka, ψ, α, β, Ke = Connections.cfs_trans_screwfastened_k(t_roof_deck, t_purlin, E_roof_deck, E_purlin, Fss, Fu_roof_deck, Fu_purlin, deck_purlin_fastener_diameter)

            #Convert the discrete stiffness to a distributed stiffness, divide by the fastener spacing.
            kx = Ke / deck_purlin_fastener_spacing

            #Collect all the outputs.
            bracing_data[i] = BracingData(kp, kϕ, kϕ_dist, kx, Lcrd, Lm)

        end

    end

    return bracing_data

end



function calculate_free_flange_stiffness(t, E, H, kϕc)

    Icantilever = 1/12*t^3   #length^4/length for distributed spring

    #Use Eq. 16 from Gao and Moen (2013) https://ascelibrary.org/doi/abs/10.1061/(ASCE)ST.1943-541X.0000860
    kxf = 1/(H^2/kϕc + (H^3/(3*E*Icantilever)))

    #There is some rotational stiffness provided by the flange to the free flange. 
    kϕf = E*Icantilever/H

    return kxf, kϕf

end


function calculate_free_flange_shear_flow_factor(Ix, H, Bc, Dc, t, c, CorZ, xcf)

    #There is shear flow in the free flange of a restrained C or Z.
    #Use Eq. 13b and 15 from Gao and Moen (2013) https://ascelibrary.org/doi/abs/10.1061/(ASCE)ST.1943-541X.0000860
    #shear flow s = q*kH where q is the uplift distributed load. 
    #Define the kH factor here for Cees and Zees.   

    if CorZ == "C"  #C

        b = Bc - c  #distance between center of screw and outside of web

        kH = ((Bc^2*t*H^2)/(4*Ix) + b)/H

        if xcf > 0   #if flange is oriented left to right from web
            kH = -kH
        end


    elseif CorZ == "Z"  #Z

        kH = (H*t*(Bc^2 + 2*Dc*Bc - (2*Dc^2*Bc)/H))/(4*Ix)

        if xcf > 0   #if free flange is oriented left to right starting at the web, where web is oriented on x=0
            kH = -kH
        end

    end

    return kH

end

function calculate_free_flange_shear_flow_properties(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vector that will hold all the outputs.
    free_flange_data = Array{PurlinLine.FreeFlangeData, 1}(undef, num_purlin_segments)

    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]

        #Define base metal thickness.
        t = purlin_line.inputs.cross_section_dimensions[section_index][2]

        #Define material properties.
        E = purlin_line.inputs.material_properties[material_index][1]

        #Define full web depth.
        H = purlin_line.inputs.cross_section_dimensions[section_index][5]

        #Define rotational stiffness provided by the deck connection to the purlin.
        kϕc = purlin_line.bracing_data[i].kϕ

        kxf, kϕf = calculate_free_flange_stiffness(t, E, H, kϕc)


        #Define purlin strong axis centroidal moment of inertia.
        Ix = purlin_line.cross_section_data[section_index].section_properties.Ixx

        #Define the purlin bottom flange width.
        Bc = purlin_line.inputs.cross_section_dimensions[section_index][4]

        #Define the purlin bottom flange lip length.
        Dc = purlin_line.inputs.cross_section_dimensions[section_index][3]

        #Define distance from top flange connection to pivot point.
        B_top = purlin_line.inputs.cross_section_dimensions[section_index][6]
        c = B_top/2  ###assume screw is centered in top flange for now 

        #Define cross-section type.
        CorZ = purlin_line.inputs.cross_section_dimensions[section_index][1]

        #Define x-axis centroid location of free flange.
        xcf = purlin_line.free_flange_cross_section_data[section_index].section_properties.xc

        kH = calculate_free_flange_shear_flow_factor(Ix, H, Bc, Dc, t, c, CorZ, xcf)

        free_flange_data[i] = FreeFlangeData(kxf, kϕf, kH)

    end

    return free_flange_data

end


function get_elastic_buckling(prop, node, elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

    node_with_stress = CUFSM.stresgen(node,P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

    curve, shapes = CUFSM.strip(prop, node_with_stress, elem, lengths, springs, constraints, neigs)

    data = CUFSM.data(prop, node_with_stress, elem, lengths, springs, constraints, neigs, curve, shapes)

    half_wavelength = [curve[i,1][1] for i=1:length(lengths)]
    load_factor = [curve[i,1][2] for i=1:length(lengths)]

    Mcr = minimum(load_factor)

    min_index = findfirst(x->x==minimum(load_factor), load_factor)    

    Lcr = half_wavelength[min_index]

    return data, Mcr, Lcr

end

function calculate_elastic_buckling_properties(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize vectors that will carry output.
    local_buckling_xx_pos = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
    local_buckling_xx_neg = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    local_buckling_yy_pos = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
    local_buckling_yy_neg = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    distortional_buckling_xx_pos = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
    distortional_buckling_xx_neg = Array{ElasticBucklingData, 1}(undef, num_purlin_segments)
 
    #Loop over all the purlin segments in the line.
    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]
        
        #Map section properties to CUFSM.
        A = purlin_line.cross_section_data[section_index].section_properties.A
        xcg = purlin_line.cross_section_data[section_index].section_properties.xc
        zcg = purlin_line.cross_section_data[section_index].section_properties.yc
        Ixx = purlin_line.cross_section_data[section_index].section_properties.Ixx
        Izz = purlin_line.cross_section_data[section_index].section_properties.Iyy
        Ixz = purlin_line.cross_section_data[section_index].section_properties.Ixy
        thetap = rad2deg(purlin_line.cross_section_data[section_index].section_properties.θ)
        I11 = purlin_line.cross_section_data[section_index].section_properties.I1
        I22 = purlin_line.cross_section_data[section_index].section_properties.I2
        unsymm = 0  #Sets Ixz=0 if unsymm = 0

        #Define the number of cross-section nodes.
        num_cross_section_nodes = size(purlin_line.cross_section_data[section_index].node_geometry)[1]

        #Initialize CUFSM node matrix.
        node = zeros(Float64, (num_cross_section_nodes, 8))

        #Add node numbers to node matrix.
        node[:, 1] .= 1:num_cross_section_nodes

        #Add nodal coordinates to node matrix.
        node[:, 2:3] .= purlin_line.cross_section_data[section_index].node_geometry

        #Add nodal restraints to node matrix.
        node[:, 4:7] .= ones(num_cross_section_nodes,4)

        #Define number of cross-section elements.
        num_cross_section_elements = size(purlin_line.cross_section_data[section_index].element_definitions)[1]

        #Initialize CUFSM elem matrix.
        elem = zeros(Float64, (num_cross_section_elements, 5))

        #Add element numbers to elem matrix.
        elem[:, 1] = 1:num_cross_section_elements

        #Add element connectivity and thickness to elem matrix.
        elem[:, 2:4] .= purlin_line.cross_section_data[section_index].element_definitions

        #Add element material reference to elem matrix.
        elem[:, 5] .= ones(num_cross_section_elements) * 100
                                
                        #lip curve bottom_flange curve web curve top_flange
        center_top_flange_node =  sum(purlin_line.cross_section_data[section_index].n[1:3]) + sum(purlin_line.cross_section_data[section_index].n_radius[1:3]) + floor(Int, purlin_line.cross_section_data[section_index].n[4]/2) + 1  #This floor command is a little dangerous.

        springs = [1 center_top_flange_node 0 purlin_line.bracing_data[i].kx 0 0 purlin_line.bracing_data[i].kϕ_dist 0 0 0]
        constraints = 0

        E = purlin_line.inputs.material_properties[material_index][1]
        ν = purlin_line.inputs.material_properties[material_index][2]
        G = E / (2 *(1 + ν))
        prop = [100 E E ν ν G]

        neigs = 1  #just need the first mode 

        ###Local buckling - xx axis, positive 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        h = purlin_line.inputs.cross_section_dimensions[section_index][5]  #this is a little dangerous
        length_inc = 5
        lengths = collect(0.25*h:0.75*h/length_inc:1.0*h)   #define to catch the local minimum

        CUFSM_local_xx_pos_data, Mcrℓ_xx_pos, Lcrℓ_xx_pos = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)   
        
        #Needed this deepcopy here to make struct work correctly.  Otherwise 'node' just kept changing.

        local_buckling_xx_pos[i] = ElasticBucklingData(CUFSM_local_xx_pos_data, Lcrℓ_xx_pos, Mcrℓ_xx_pos)

        ###Local buckling - xx axis, negative 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = -1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        h = purlin_line.inputs.cross_section_dimensions[section_index][5]  #this is a little dangerous
        length_inc = 5
        lengths = collect(0.25*h:0.75*h/length_inc:1.0*h)   #define to catch the local minimum

        CUFSM_local_xx_neg_data, Mcrℓ_xx_neg, Lcrℓ_xx_neg = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        local_buckling_xx_neg[i] = ElasticBucklingData(CUFSM_local_xx_neg_data, Lcrℓ_xx_neg, Mcrℓ_xx_neg)


        ###local buckling - yy axis, positive
        
        #Define reference loads.  
        P = 0.0
        Mxx = 0.0  
        Mzz = 1.0  #assume centroidal moment always for now
        M11 = 0.0
        M22 = 0.0

        #Try Lcrd as a guide for finding the half-wavelength of the flange and lip (unstiffened element).
        length_inc = 5
        lengths = collect(0.25 * purlin_line.bracing_data[i].Lcrd:(1.0 * purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * purlin_line.bracing_data[i].Lcrd)   #define to catch the local minimum

        CUFSM_local_yy_pos_data, Mcrℓ_yy_pos, Lcrℓ_yy_pos = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        local_buckling_yy_pos[i] = ElasticBucklingData(CUFSM_local_yy_pos_data, Lcrℓ_yy_pos, Mcrℓ_yy_pos)
  
        ###local buckling - yy axis, negative
        
        #Define reference loads.  
        P = 0.0
        Mxx = 0.0  
        Mzz = -1.0  #assume centroidal moment always for now
        M11 = 0.0
        M22 = 0.0
    
        length_inc = 5
        #Try Lcrd as a guide for finding the half-wavelength of the flange and lip (unstiffened element).
        lengths = collect(0.25 * purlin_line.bracing_data[i].Lcrd:(1.0 * purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * purlin_line.bracing_data[i].Lcrd)   #define to catch the local minimum

        CUFSM_local_yy_neg_data, Mcrℓ_yy_neg, Lcrℓ_yy_neg = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        local_buckling_yy_neg[i] = ElasticBucklingData(CUFSM_local_yy_neg_data, Lcrℓ_yy_neg, Mcrℓ_yy_neg)

        ###Distortional buckling - xx axis, positive

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        length_inc = 5
        lengths = collect(0.75 * purlin_line.bracing_data[i].Lcrd:(0.50 * purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * purlin_line.bracing_data[i].Lcrd)  #define to catch distortional minimum

        CUFSM_dist_pos_data, Mcrd_pos, Lcrd_pos_CUFSM = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        distortional_buckling_xx_pos[i] = ElasticBucklingData(CUFSM_dist_pos_data, Lcrd_pos_CUFSM, Mcrd_pos)

         ###Distortional buckling - xx axis, negative

        #Define reference loads.  
        P = 0.0
        Mxx = -1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        length_inc = 5
        lengths = collect(0.75 * purlin_line.bracing_data[i].Lcrd:(0.50 * purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * purlin_line.bracing_data[i].Lcrd)  #define to catch distortional minimum

        CUFSM_dist_neg_data, Mcrd_neg, Lcrd_neg_CUFSM = get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        distortional_buckling_xx_neg[i] = ElasticBucklingData(CUFSM_dist_neg_data, Lcrd_neg_CUFSM, Mcrd_neg)

    end

    return local_buckling_xx_pos, local_buckling_xx_neg, local_buckling_yy_pos, local_buckling_yy_neg, distortional_buckling_xx_pos, distortional_buckling_xx_neg


end


function calculate_yielding_flexural_strength(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    yielding_flexural_strength_xx = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)
    yielding_flexural_strength_yy = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)
    yielding_flexural_strength_free_flange_yy = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)


    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]

        ###strong axis flexure, local-global interaction
        Fy = purlin_line.inputs.material_properties[material_index][3]
        Ixx = purlin_line.cross_section_data[section_index].section_properties.Ixx
        ho = purlin_line.inputs.cross_section_dimensions[section_index][5]
        cy_bottom = purlin_line.cross_section_data[section_index].section_properties.yc  #distance from neutral axis to bottom outer fiber
        cy_top = ho - cy_bottom #distance from neutral axis to top outer fiber
        Sxx_pos = Ixx/cy_top
        Sxx_neg = Ixx/cy_bottom
        My_xx_pos = Fy*Sxx_pos
        My_xx_neg = Fy*Sxx_neg
        My_xx = minimum([My_xx_pos My_xx_neg])  #first yield criterion for AISI 

        yielding_flexural_strength_xx[i] = YieldingFlexuralStrengthData(Sxx_pos, Sxx_neg, My_xx_pos, My_xx_neg, My_xx, 0.0)   #make eMy zero here since it is not used

        ###weak axis flexure, local-global interaction
        Iyy = purlin_line.cross_section_data[section_index].section_properties.Iyy

        #distance from neutral axis to (-x or left) outer fiber
        #Positive moment is applied when this outer fiber is compressed.
        cx_minusx = purlin_line.cross_section_data[section_index].section_properties.xc - minimum(purlin_line.cross_section_data[section_index].node_geometry[:,1])
        #distance from neutral axis to (+x or right) outer fiber
        #Negative moment is applied when this outer fiber is compressed.
        cx_plusx = maximum(purlin_line.cross_section_data[section_index].node_geometry[:,1]) - purlin_line.cross_section_data[section_index].section_properties.xc 
 
        Syy_pos = Iyy / cx_minusx
        Syy_neg = Iyy / cx_plusx
 
        My_yy_pos = Fy*Syy_pos
        My_yy_neg = Fy*Syy_neg
        My_yy = minimum([My_yy_pos My_yy_neg])  #first yield criterion for AISI 
 
        yielding_flexural_strength_yy[i] = YieldingFlexuralStrengthData(Syy_pos, Syy_neg, My_yy_pos, My_yy_neg, My_yy, 0.0)  #set eMy=0.0 for now

        ###free flange yy-axis, local-global interaction

        #define free flange properties
        Iyyf = purlin_line.free_flange_cross_section_data[section_index].section_properties.Iyy

        #distance from neutral axis to (-x or left) outer fiber
        #Positive moment is applied when this outer fiber is compressed.
        cxf_minusx = purlin_line.free_flange_cross_section_data[section_index].section_properties.xc - minimum(purlin_line.free_flange_cross_section_data[section_index].node_geometry[:,1])
        #distance from neutral axis to (+x or right) outer fiber
        #Negative moment is applied when this outer fiber is compressed.
        cxf_plusx = maximum(purlin_line.free_flange_cross_section_data[section_index].node_geometry[:,1]) - purlin_line.free_flange_cross_section_data[section_index].section_properties.xc 

        Syy_pos_free_flange = Iyyf / cxf_minusx
        Syy_neg_free_flange = Iyyf / cxf_plusx

        My_yy_pos_free_flange = Fy*Syy_pos_free_flange
        My_yy_neg_free_flange = Fy*Syy_neg_free_flange
        My_yy_free_flange = minimum([My_yy_pos_free_flange My_yy_neg_free_flange])  #first yield criterion for AISI 

        #Factored yield moment is needed for the free flange to perform AISI interaction checks.

        if purlin_line.inputs.design_code == "AISI S100-16 ASD"
            ASDorLRFD = 0
        elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
            ASDorLRFD = 1
        else 
            ASDorLRFD = 2   #nominal
        end

        Mcrℓ_yy_free_flange = 10.0^10 #Make this a big number so we just get back eMy
        My_yy_free_flange, eMy_yy_free_flange = AISIS10016.f321(My_yy_free_flange, Mcrℓ_yy_free_flange, ASDorLRFD)

        yielding_flexural_strength_free_flange_yy[i] = YieldingFlexuralStrengthData(Syy_pos_free_flange, Syy_neg_free_flange, My_yy_pos_free_flange, My_yy_neg_free_flange, My_yy_free_flange, eMy_yy_free_flange)

    end

    return yielding_flexural_strength_xx, yielding_flexural_strength_yy, yielding_flexural_strength_free_flange_yy

end

function calculate_local_global_flexural_strength(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    local_global_flexural_strength_xx = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)
    local_global_flexural_strength_yy = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)
    local_global_flexural_strength_free_flange_yy = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)


    if purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    else
        ASDorLRFD = 2   #nominal
    end

    for i = 1:num_purlin_segments

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        Mne_xx = purlin_line.yielding_flexural_strength_xx[i].My  #handle global buckling in the ThinWalledBeam second order analysis
        
        Mcrℓ_xx_pos = purlin_line.local_buckling_xx_pos[i].Mcr
        λ_ℓ_pos = sqrt(Mne_xx/Mcrℓ_xx_pos)

        if λ_ℓ_pos < 0.776   #inelastic reserve is in play

            Sc = purlin_line.yielding_flexural_strength_xx[i].S_pos
            St = purlin_line.yielding_flexural_strength_xx[i].S_neg
            Z =  purlin_line.cross_section_data[section_index].plastic_section_properties.Z
            Fy = purlin_line.inputs.material_properties[material_index][3]
            lambda_l, Cyl, Mp, Myc, Myt3, Mnℓ_xx_pos, eMnℓ_xx_pos = AISIS10016.f323(Mne_xx, Mcrℓ_xx_pos, Sc, St, Z, Fy, ASDorLRFD)

        else   #no inelastic reserve

            Mnℓ_xx_pos, eMnℓ_xx_pos =  AISIS10016.f321(Mne_xx, purlin_line.local_buckling_xx_pos[i].Mcr, ASDorLRFD)

        end


        Mcrℓ_xx_neg = purlin_line.local_buckling_xx_neg[i].Mcr
        λ_ℓ_neg = sqrt(Mne_xx/Mcrℓ_xx_neg)

        if λ_ℓ_neg < 0.776   #inelastic reserve is in play

            Sc = purlin_line.yielding_flexural_strength_xx[i].S_neg
            St = purlin_line.yielding_flexural_strength_xx[i].S_pos
            Z =  purlin_line.cross_section_data[section_index].plastic_section_properties.Z
            Fy = purlin_line.inputs.material_properties[material_index][3]
            lambda_l, Cyl, Mp, Myc, Myt3, Mnℓ_xx_neg, eMnℓ_xx_neg = AISIS10016.f323(Mne_xx, Mcrℓ_xx_neg, Sc, St, Z, Fy, ASDorLRFD)

        else   #no inelastic reserve

            Mnℓ_xx_neg, eMnℓ_xx_neg =  AISIS10016.f321(Mne_xx, purlin_line.local_buckling_xx_neg[i].Mcr, ASDorLRFD)

        end

        local_global_flexural_strength_xx[i] = LocalGlobalFlexuralStrengthData(Mne_xx, Mnℓ_xx_pos, Mnℓ_xx_neg, eMnℓ_xx_pos, eMnℓ_xx_neg)

        ###weak axis flexure, local-global interaction
        Mne_yy = purlin_line.yielding_flexural_strength_yy[i].My

        Mnℓ_yy_pos, eMnℓ_yy_pos = AISIS10016.f321(Mne_yy, purlin_line.local_buckling_yy_pos[i].Mcr, ASDorLRFD)

        Mnℓ_yy_neg, eMnℓ_yy_neg = AISIS10016.f321(Mne_yy, purlin_line.local_buckling_yy_neg[i].Mcr, ASDorLRFD)

        local_global_flexural_strength_yy[i] = LocalGlobalFlexuralStrengthData(Mne_yy, Mnℓ_yy_pos, Mnℓ_yy_neg, eMnℓ_yy_pos, eMnℓ_yy_neg)


        ###free flange yy-axis, local-global interaction
        Mne_yy_free_flange = purlin_line.yielding_flexural_strength_free_flange_yy[i].My 

        #Assume no local buckling for now in the free flange strength calculation.  Set Mcrℓ to Mne times a big number. 

        Mnℓ_yy_pos_free_flange, eMnℓ_yy_pos_free_flange = AISIS10016.f321(Mne_yy_free_flange, Mne_yy_free_flange * 1000, ASDorLRFD)

        Mnℓ_yy_neg_free_flange, eMnℓ_yy_neg_free_flange = AISIS10016.f321(Mne_yy_free_flange, Mne_yy_free_flange * 1000, ASDorLRFD)

        local_global_flexural_strength_free_flange_yy[i] = LocalGlobalFlexuralStrengthData(Mne_yy_free_flange, Mnℓ_yy_pos_free_flange, Mnℓ_yy_neg_free_flange, eMnℓ_yy_pos_free_flange, eMnℓ_yy_neg_free_flange)

    end

    return local_global_flexural_strength_xx, local_global_flexural_strength_yy, local_global_flexural_strength_free_flange_yy

end

function calculate_distortional_flexural_strength(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    distortional_flexural_strength_xx = Array{DistortionalFlexuralStrengthData, 1}(undef, num_purlin_segments)

    if purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    else
        ASDorLRFD = 2   #nominal
    end


    for i = 1:num_purlin_segments

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]

        My = purlin_line.yielding_flexural_strength_xx[i].My
        Mcrd_xx_pos = purlin_line.distortional_buckling_xx_pos[i].Mcr
        λ_d_pos = sqrt(My/Mcrd_xx_pos)


        if λ_d_pos < 0.673   #inelastic reserve is in play

            Sc = purlin_line.yielding_flexural_strength_xx[i].S_pos
            St = purlin_line.yielding_flexural_strength_xx[i].S_neg
            Z =  purlin_line.cross_section_data[section_index].plastic_section_properties.Z
            Fy = purlin_line.inputs.material_properties[material_index][3]

            lambda_d, Cyd, Mp, Myc, Myt3, Mnd_xx_pos, eMnd_xx_pos = AISIS10016.f43(My, Mcrd_xx_pos, Sc, St, Z, Fy, ASDorLRFD)

        else

            
            Mnd_xx_pos, eMnd_xx_pos = AISIS10016.f411(purlin_line.yielding_flexural_strength_xx[i].My, purlin_line.distortional_buckling_xx_pos[i].Mcr, ASDorLRFD)

        end

        Mcrd_xx_neg = purlin_line.distortional_buckling_xx_neg[i].Mcr
        λ_d_neg = sqrt(My/Mcrd_xx_neg)


        if λ_d_neg < 0.673   #inelastic reserve is in play

            Sc = purlin_line.yielding_flexural_strength_xx[i].S_neg  #compression is associated with negative moment here
            St = purlin_line.yielding_flexural_strength_xx[i].S_pos
            Z =  purlin_line.cross_section_data[section_index].plastic_section_properties.Z
            Fy = purlin_line.inputs.material_properties[material_index][3]

            lambda_d, Cyd, Mp, Myc, Myt3, Mnd_xx_neg, eMnd_xx_neg = AISIS10016.f43(My, Mcrd_xx_neg, Sc, St, Z, Fy, ASDorLRFD)

        else

            Mnd_xx_neg, eMnd_xx_neg = AISIS10016.f411(purlin_line.yielding_flexural_strength_xx[i].My, purlin_line.distortional_buckling_xx_neg[i].Mcr, ASDorLRFD)

        end

        distortional_flexural_strength_xx[i] = DistortionalFlexuralStrengthData(Mnd_xx_pos, Mnd_xx_neg, eMnd_xx_pos, eMnd_xx_neg)

    end

    return distortional_flexural_strength_xx

end

function calculate_torsion_strength(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vector that will hold all the outputs.
    torsion_strength = Array{TorsionStrengthData, 1}(undef, num_purlin_segments)
    
    if purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    else
        ASDorLRFD = 2  #nominal
    end

    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]
        
        Cw = purlin_line.cross_section_data[section_index].section_properties.Cw
        Fy = purlin_line.inputs.material_properties[material_index][3]

        #This is the maximum magnitude of the warping stress function.  
        Wn = maximum(abs.(purlin_line.cross_section_data[section_index].section_properties.wn))

        Bn, eBn = AISIS10024.h411(Cw, Fy, Wn, ASDorLRFD)

        torsion_strength[i] = TorsionStrengthData(Wn, Bn, eBn)

    end

    return torsion_strength

end


function calculate_shear_strength(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Initialize a vector that will hold all the outputs.
    shear_strength = Array{ShearStrengthData, 1}(undef, num_purlin_segments)

    if purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    else
        ASDorLRFD = 2  #nominal
    end

    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = purlin_line.inputs.segments[i][3]

        #Set a, the shear stiffener spacing, to the sum of the purlin segment lengths.  This assumes that shear stiffeners are not provided.
        sum_purlin_segments = sum([purlin_line.inputs.segments[i][1] for i=1:size(purlin_line.inputs.segments)[1]])
        a = sum_purlin_segments

        #Define base metal thickness.
        t = purlin_line.inputs.cross_section_dimensions[section_index][2]

        #Define material properties.
        E = purlin_line.inputs.material_properties[material_index][1]
        μ = purlin_line.inputs.material_properties[material_index][2]
        Fy = purlin_line.inputs.material_properties[material_index][3]

        #Depth of flat portion of web.
        full_web_depth = purlin_line.inputs.cross_section_dimensions[section_index][5]
        bottom_flange_web_outside_radius = purlin_line.inputs.cross_section_dimensions[section_index][14]
        top_flange_web_outside_radius = purlin_line.inputs.cross_section_dimensions[section_index][15]
        h_flat = full_web_depth - bottom_flange_web_outside_radius - top_flange_web_outside_radius

        #Calculate plate buckling coefficient.
        kv  = AISIS10016.g233(a, h_flat)

        #Calculate shear buckling stress.
        Fcrv = AISIS10016.g232(E, μ, kv, h_flat, t)
        Vcr = AISIS10016.g231(h_flat, t, Fcrv)

        #Calculate shear buckling strength.
        Vn, eVn = AISIS10016.g21(h_flat, t, Fy, Vcr, ASDorLRFD)

        shear_strength[i] = ShearStrengthData(h_flat, kv, Fcrv, Vcr, Vn, eVn)

    end

    return shear_strength

end 


#Calculate the web crippling strength at each support location.
function calculate_web_crippling_strength(purlin_line)

    ###Assumptions...
    #Purlin is always fastened to a support.
    #Purlin always has stiffened or partially stiffened flanges.
    #The loading is always a one-flange loading.

    if purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    elseif purlin_line.inputs.design_code == "AISI S100-16 nominal"
        ASDorLRFD = 2
    end

    #Define the number of supports along the purlin line.
    num_supports = length(purlin_line.inputs.support_locations)

    #Initialize a vector that will hold all the web crippling outputs.
    web_crippling = Array{WebCripplingData, 1}(undef, num_supports)

    #Define coordinates along purlin line where segment properties change.
    purlin_range = [0; cumsum([purlin_line.inputs.segments[i][1] for i=1:size(purlin_line.inputs.segments)[1]])]
          
    for i = 1:num_supports

        #Find purlin segment that coincides with a support.
        purlin_range_indices = findall(x->(x < purlin_line.inputs.support_locations[i]) | (x ≈ purlin_line.inputs.support_locations[i]) , purlin_range)
        if purlin_range_indices == [1]
            segment_index = 1
        else
            segment_index = maximum(purlin_range_indices) - 1
        end 

        #Define if support is at the end or in the interior of a purlin line.
        if (purlin_line.inputs.support_locations[i] ≈ purlin_range[1]) | (purlin_line.inputs.support_locations[i] ≈ purlin_range[end])
            load_location = "End"
        else
            load_location = "Interior"
        end

        #Define section and material indices to use for web crippling definitions.
        section_index = purlin_line.inputs.segments[segment_index][2]
        material_index = purlin_line.inputs.segments[segment_index][3]

        t = purlin_line.inputs.cross_section_dimensions[section_index][2]
        Fy = purlin_line.inputs.material_properties[material_index][3]
       
        full_web_depth = purlin_line.inputs.cross_section_dimensions[section_index][5]
        bottom_flange_web_outside_radius = purlin_line.inputs.cross_section_dimensions[section_index][14]
        top_flange_web_outside_radius = purlin_line.inputs.cross_section_dimensions[section_index][15]
        h_flat = full_web_depth - bottom_flange_web_outside_radius - top_flange_web_outside_radius

        θ = purlin_line.inputs.cross_section_dimensions[section_index][10]  #angle between web plane and surface plane 

        if purlin_line.inputs.cross_section_dimensions[section_index][1] == "Z"

            #Use AISI S100-16 Table G5-3 for Z-sections.
            table_g53 = AISIS10016.table_g53()  
           

            web_crippling_coeff = filter(row -> row.support_condition == "Fastened to Support", table_g53)
            web_crippling_coeff = filter(row -> row.flange_condition == "Stiffened or Partially Stiffened Flanges", web_crippling_coeff)
            web_crippling_coeff = filter(row -> row.load_case == "One-Flange Loading or Reaction", web_crippling_coeff)
            web_crippling_coeff = filter(row -> row.load_location== load_location, web_crippling_coeff)

            C = web_crippling_coeff.C[1]
            C_R = web_crippling_coeff.C_R[1]
            R = purlin_line.inputs.cross_section_dimensions[section_index][14] - t  #inside radius
            C_N = web_crippling_coeff.C_N[1]
            N = purlin_line.inputs.frame_flange_width
            C_h = web_crippling_coeff.C_h[1]
            ϕ_w = web_crippling_coeff.LRFD[1]
            Ω_w = web_crippling_coeff.ASD[1]

            Pn, ePn = AISIS10016.g51(t, h_flat, Fy, θ, C, C_R, R, C_N, N, C_h, ϕ_w, Ω_w, ASDorLRFD)

            web_crippling[i] = WebCripplingData(web_crippling_coeff.support_condition[1], web_crippling_coeff.flange_condition[1], web_crippling_coeff.load_case[1], web_crippling_coeff.load_location[1], C, C_R, R, C_N, N, C_h, ϕ_w, Ω_w, Pn, ePn)

        elseif purlin_line.inputs.cross_section_dimensions[section_index][1] == "C"

            #Use AISI S100-16 Table G5-2 for C-sections.
            table_g52 = StructuresKit.AISIS10016.table_g52()  
           

            web_crippling_coeff = filter(row -> row.support_condition == "Fastened to Support", table_g52)
            web_crippling_coeff = filter(row -> row.flange_condition == "Stiffened or Partially Stiffened Flanges", web_crippling_coeff)
            web_crippling_coeff = filter(row -> row.load_case == "One-Flange Loading or Reaction", web_crippling_coeff)
            web_crippling_coeff = filter(row -> row.load_location== load_location, web_crippling_coeff)

            C = web_crippling_coeff.C[1]
            C_R = web_crippling_coeff.C_R[1]
            R = purlin_line.inputs.cross_section_dimensions[section_index][14] - t  #inside radius
            C_N = web_crippling_coeff.C_N[1]
            N = purlin_line.inputs.frame_flange_width
            C_h = web_crippling_coeff.C_h[1]
            ϕ_w = web_crippling_coeff.LRFD[1]
            Ω_w = web_crippling_coeff.ASD[1]

            Pn, ePn = AISIS10016.g51(t, h_flat, Fy, θ, C, C_R, R, C_N, N, C_h, ϕ_w, Ω_w, ASDorLRFD)

            web_crippling[i] = WebCripplingData(web_crippling_coeff.support_condition[1], web_crippling_coeff.flange_condition[1], web_crippling_coeff.load_case[1], web_crippling_coeff.load_location[1], C, C_R, R, C_N, N, C_h, ϕ_w, Ω_w, Pn, ePn)

        end

    end

    return web_crippling

end


function discretize_purlin_line(purlin_line)

    #Define the purlin segment properties.
    num_purlin_segments = size(purlin_line.inputs.segments)[1]

    #Intialize data structure for ThinWalledBeam member_definitions.
    member_definitions = Vector{Tuple{Float64, Float64, Int64, Int64}}(undef, num_purlin_segments)

    #Loop over the purlin line segments.
    for i=1:num_purlin_segments

        L = purlin_line.inputs.segments[i][1]
        dL = L / 20  #Hard coded for now.
        section_id = purlin_line.inputs.segments[i][2]
        material_id = purlin_line.inputs.segments[i][3]

        #L(1) dL(2) section_properties(3) material_properties(4) 
                             
        member_definitions[i] = (L, dL, section_id, material_id)

    end

    #Add purlin line discretization to purlin_line data structure.
    dz, z, dm = Mesh.define_line_element(member_definitions)

    return member_definitions, dz, z, dm

end


"""
    define(design_code, segments, spacing, roof_slope, cross_section_dimensions, material_properties, deck_details, deck_material_properties, frame_flange_width, support_locations, bridging_locations)

Returns a PurlinLine model built from user inputs.
"""

function build(design_code, segments, spacing, roof_slope, cross_section_dimensions, material_properties, deck_details, deck_material_properties, frame_flange_width, support_locations, purlin_frame_connections, bridging_locations)

    #Create the data structure.
    purlin_line = PurlinLineObject()

    #Capture inputs.
    purlin_line.inputs = PurlinLine.Inputs(design_code, segments, spacing, roof_slope, cross_section_dimensions, material_properties, deck_details, deck_material_properties, frame_flange_width, support_locations, purlin_frame_connections, bridging_locations)

    #CALCULATIONS LAYER

    #Define the purlin cross-section discretization and calculate section properties.
    n = [4, 4, 5, 4, 4]
    n_radius = [4, 4, 4, 4]
    purlin_line.cross_section_data = PurlinLine.define_purlin_section(purlin_line.inputs.cross_section_dimensions, n, n_radius)

    #Define the purlin free flange cross-section discretization and calculate section properties.
    n = [4, 4, 4]
    n_radius = [4, 4]
    purlin_line.free_flange_cross_section_data = PurlinLine.define_purlin_free_flange_section(purlin_line.inputs.cross_section_dimensions, n, n_radius)

    #Calculate deck bracing properties. 
    purlin_line.bracing_data = PurlinLine.define_deck_bracing_properties(purlin_line)

    #Calculate free flange shear flow properties, including bracing stiffness from web and conversion factor from purlin line load to shear flow.
    purlin_line.free_flange_data = calculate_free_flange_shear_flow_properties(purlin_line)

    #Calculate the critical elastic local buckling and distortional buckling properties for each purlin line segment.
    purlin_line.local_buckling_xx_pos, purlin_line.local_buckling_xx_neg, purlin_line.local_buckling_yy_pos, purlin_line.local_buckling_yy_neg, purlin_line.distortional_buckling_xx_pos, purlin_line.distortional_buckling_xx_neg  = calculate_elastic_buckling_properties(purlin_line)

    #Calculate the first yield flexural strengths for each purlin line segment.  
    purlin_line.yielding_flexural_strength_xx, purlin_line.yielding_flexural_strength_yy, purlin_line.yielding_flexural_strength_free_flange_yy = calculate_yielding_flexural_strength(purlin_line)

    #Calculate the local-global flexural strengths for each purlin line segment.   
    purlin_line.local_global_flexural_strength_xx, purlin_line.local_global_flexural_strength_yy, purlin_line.local_global_flexural_strength_free_flange_yy = calculate_local_global_flexural_strength(purlin_line)

    #Calculate distortional buckling strengths for each purlin line segment.
    purlin_line.distortional_flexural_strength_xx = calculate_distortional_flexural_strength(purlin_line)

    #Calculate torsion strength for each purlin line segment.
    purlin_line.torsion_strength = calculate_torsion_strength(purlin_line)

    #Calculate shear strength for each purlin line segment.
    purlin_line.shear_strength = calculate_shear_strength(purlin_line)

    #Calculate web crippling strength at each support.
    purlin_line.web_crippling = calculate_web_crippling_strength(purlin_line)

    return purlin_line

end


function thin_walled_beam_interface(purlin_line)

    #Discretize purlin line.
    member_definitions, dz, z, m = discretize_purlin_line(purlin_line)

    #Define ThinWalledBeam section property inputs.
    #Ix Iy Ixy J Cw

    num_purlin_sections = size(purlin_line.inputs.cross_section_dimensions)[1]
    section_properties = Vector{Tuple{Float64, Float64, Float64, Float64, Float64}}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        #Note -Ixy here since +y in ThinWalledBeam formulation is pointing down.
        section_properties[i] = (purlin_line.cross_section_data[i].section_properties.Ixx, purlin_line.cross_section_data[i].section_properties.Iyy, -purlin_line.cross_section_data[i].section_properties.Ixy, purlin_line.cross_section_data[i].section_properties.J, purlin_line.cross_section_data[i].section_properties.Cw)

    end


    #Define ThinWalledBeam material property inputs.
    num_purlin_materials = size(purlin_line.inputs.material_properties)[1]

    material_properties = Vector{Tuple{Float64, Float64}}(undef, num_purlin_materials)

    for i = 1:num_purlin_materials

        material_properties[i] = (purlin_line.inputs.material_properties[i][1], purlin_line.inputs.material_properties[i][2])

    end

    #Define the lateral and rotational stiffness magnitudes for ThinWalledBeam.
    num_purlin_segments = size(purlin_line.bracing_data)[1]

    kx_segments = Vector{Float64}(undef, num_purlin_segments)
    kϕ_segments = Vector{Float64}(undef, num_purlin_segments)

    for i=1:num_purlin_segments

        kx_segments[i] = purlin_line.bracing_data[i].kx 
        kϕ_segments[i]  = purlin_line.bracing_data[i].kϕ
 
    end

    #ThinWalledBeam accepts multiple springs.   Only one kx and kϕ are used here.
    kx = Array{Array{Float64}}(undef, 1)
    kϕ = Array{Array{Float64}}(undef, 1)

    num_nodes = length(z)
    kx[1] = zeros(Float64, num_nodes)
    kϕ[1] = zeros(Float64, num_nodes)
    kx[1] .= kx_segments[m]
    kϕ[1] .= kϕ_segments[m]

    #Define the lateral spring location for ThinWalledBeam.    

    #Calculate the y-distance from the purlin shear center to the lateral translational spring.
    spring_location_segment = Vector{Float64}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        ys = purlin_line.cross_section_data[i].section_properties.ys  #distance from bottom fiber of purlin to shear center
        h = purlin_line.inputs.cross_section_dimensions[i][5]   #out to out purlin height

        spring_location_segment[i] = h - ys  

    end

    #Define location of translational spring at each node.
    ay_kx = Array{Array{Float64}}(undef, 1)
    ay_kx[1] = Mesh.create_line_element_property_array(member_definitions, m, dz, spring_location_segment, 3, 1)

    #Define purlin line support locations for ThinWalledBeam.
    #location where u=v=ϕ=0
    supports = purlin_line.inputs.support_locations

    #Define purlin line end boundary conditions for ThinWalledBeam.

    end_boundary_conditions = Array{Int64}(undef, 2)

    purlin_line_length = sum([purlin_line.inputs.segments[i][1] for i=1:size(purlin_line.inputs.segments)[1]])

    #type=1 u''=v''=ϕ''=0 (simply supported), type=2 u'=v'=ϕ'=0  (fixed), type=3 u''=v''=ϕ''=u'''=v'''=ϕ'''=0 (free end, e.g., a cantilever)

    #z=0 (left) end
    if supports[1] == 0.0
        end_boundary_conditions[1] = 1 #pin
    else
        end_boundary_conditions[1] = 3  #cantilever
    end

    #z=purlin_line_length (right) end
    if supports[end] == purlin_line_length
        end_boundary_conditions[2] = 1
    else
        end_boundary_conditions[2] = 3  #cantilever
    end

    #Calculate load magnitudes from user-defined pressure for ThinWalledBeam.
    q = purlin_line.applied_pressure * purlin_line.inputs.spacing #go from pressure to line load

    num_nodes = length(z)

    if q<0   #uplift wind pressure
        qx = zeros(num_nodes)
        qy = q .* ones(Float64, num_nodes)
    elseif q>= 0 #gravity pressure
        qx = -q .* sin(deg2rad(purlin_line.inputs.roof_slope)) .* ones(Float64, num_nodes)
        qy = q .* cos(deg2rad(purlin_line.inputs.roof_slope)) .* ones(Float64, num_nodes)
    end

    #Calculate the load locations for ThinWalledBeam.
    ax_purlin_section = Vector{Float64}(undef, num_purlin_sections)
    ay_purlin_section = Vector{Float64}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        center_top_flange_node_index = sum(purlin_line.cross_section_data[i].n[1:3]) + sum(purlin_line.cross_section_data[i].n_radius[1:3]) + floor(Int,purlin_line.cross_section_data[i].n[4]/2) + 1

        ax_purlin_section[i] = purlin_line.cross_section_data[i].node_geometry[center_top_flange_node_index, 1] - purlin_line.cross_section_data[i].section_properties.xs

        t = purlin_line.inputs.cross_section_dimensions[i][2]

        ay_purlin_section[i] = (purlin_line.cross_section_data[i].node_geometry[center_top_flange_node_index, 2] + t/2) - purlin_line.cross_section_data[i].section_properties.ys
        
    end

    #Define the load location at each node.
    ax = Mesh.create_line_element_property_array(member_definitions, m, dz, ax_purlin_section, 3, 1)
    ay = Mesh.create_line_element_property_array(member_definitions, m, dz, ay_purlin_section, 3, 1)

    return z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports

end

function calculate_free_flange_axial_force(Mxx, member_definitions, purlin_line)

    num_purlin_sections = size(purlin_line.inputs.cross_section_dimensions)[1]

    P_unit = zeros(Float64, num_purlin_sections)

    #Loop over the purlin cross-sections in the line.
    for i = 1:num_purlin_sections

        #Find web node at H/5.
        web_index = purlin_line.cross_section_data[i].n[1] + purlin_line.cross_section_data[i].n_radius[1] + purlin_line.cross_section_data[i].n[2] + purlin_line.cross_section_data[i].n_radius[2] + 1 + 1

        #Use the local_buckling_xx_pos node geometry and reference stress from CUFSM (Mxx = 1).
        dx = diff(purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,2])
        dy = diff(purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,3])
        ds = sqrt.(dx.^2 .+ dy.^2)
        s = [0; cumsum(ds)]   #line coordinates around free flange

        #Integrate the reference stress (Mxx = 1.0) in the free flange to find the reference axial force.   
        stress = purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,8] 
        t = purlin_line.inputs.cross_section_dimensions[i][2]
        P_unit[i] = integrate(s, stress) * t

    end

    #Scale the reference axial force along the purlin line to define the axial force in the free flange.
    #The sign convention for P is + (compression), - (tension) to match StructuresKit.BeamColumn.
    dz = diff(purlin_line.model.z)
    P = Mesh.create_line_element_property_array(member_definitions, purlin_line.model.m, dz, P_unit, 3, 1) .* Mxx

    return P

end


function beam_column_interface(purlin_line)

    #Discretize purlin line.
    member_definitions, dz, z, m = discretize_purlin_line(purlin_line)

    #Define the number of purlin cross-sections.
    num_purlin_sections = size(purlin_line.inputs.cross_section_dimensions)[1]

    #Initialize an array of tuples to hold the free flange section properties.
    section_properties = Vector{Tuple{Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64,}}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        Af = purlin_line.free_flange_cross_section_data[i].section_properties.A
        Ixf = purlin_line.free_flange_cross_section_data[i].section_properties.Ixx
        Iyf = purlin_line.free_flange_cross_section_data[i].section_properties.Iyy
        Jf = purlin_line.free_flange_cross_section_data[i].section_properties.J
        Cwf = purlin_line.free_flange_cross_section_data[i].section_properties.Cw
        xcf = purlin_line.free_flange_cross_section_data[i].section_properties.xc
        ycf = purlin_line.free_flange_cross_section_data[i].section_properties.yc
        xsf = purlin_line.free_flange_cross_section_data[i].section_properties.xs
        ysf = purlin_line.free_flange_cross_section_data[i].section_properties.ys

        section_properties[i] = (Af, Ixf, Iyf, Jf, Cwf, xcf, ycf, xsf, ysf)

    end


    #Define BeamColumn material property inputs.
    num_purlin_materials = size(purlin_line.inputs.material_properties)[1]

    material_properties = Vector{Tuple{Float64, Float64}}(undef, num_purlin_materials)

    for i = 1:num_purlin_materials

        material_properties[i] = (purlin_line.inputs.material_properties[i][1], purlin_line.inputs.material_properties[i][2])

    end

   
    num_purlin_segments = size(purlin_line.bracing_data)[1]

    #Define kxf along the purlin line.
    kxf_segments = [purlin_line.free_flange_data[i].kxf for i=1:num_purlin_segments]

    num_nodes = length(z)
    kxf = zeros(Float64, num_nodes)
    kxf .= kxf_segments[m]

    #There is no kyf assumed.
    kyf = zeros(Float64, num_nodes)

    #Define kϕf along the purlin line.
    kϕf_segments = [purlin_line.free_flange_data[i].kϕf for i=1:num_purlin_segments]
    kϕf = zeros(Float64, num_nodes)
    kϕf .= kϕf_segments[m]    

    #Assume the lateral spring acts at the free flange centroid.  This means hx =hy = 0.
    hxf = zeros(Float64, num_nodes)
    hyf = zeros(Float64, num_nodes)

    #Define shear flow force in free flange.

    #Define the purlin segment properties.
    kH_segments = [purlin_line.free_flange_data[i].kH for i=1:num_purlin_segments]
    kH = zeros(Float64, num_nodes)
    kH .= kH_segments[m]

    #The shear flow is applied at the free flange centerline.  The distance ay in StructuresKit.BeamColumn is the distance from the shear center to the load along the centroidal y-axis.   Since the shear center for just the free flange is close to the free flange centerline, assume ay= 0.  
    
    ayf = zeros(Float64, num_nodes)

    #There is no qyf so this can be set to zero.
    axf = zeros(Float64, num_nodes)

    #Define supports.   Combine frame supports and intermediate bridging here.
    supports = sort(unique([purlin_line.inputs.support_locations; purlin_line.inputs.bridging_locations]))

    #Define purlin line end boundary conditions for BeamColumn.

    end_boundary_conditions = Array{Int64}(undef, 2)

    purlin_line_length = sum([purlin_line.inputs.segments[i][1] for i=1:size(purlin_line.inputs.segments)[1]])

    #type=1 u''=v''=ϕ''=0 (simply supported), type=2 u'=v'=ϕ'=0  (fixed), type=3 u''=v''=ϕ''=u'''=v'''=ϕ'''=0 (free end, e.g., a cantilever)

    #z=0 (left) end
    if supports[1] == 0.0
        end_boundary_conditions[1] = 1 #pin
    else
        end_boundary_conditions[1] = 3  #cantilever
    end

    #z=purlin_line_length (right) end
    if supports[end] == purlin_line_length
        end_boundary_conditions[2] = 1
    else
        end_boundary_conditions[2] = 3  #cantilever
    end


    return z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, kH, hxf, hyf, axf, ayf, end_boundary_conditions, supports

end


function calculate_flexural_capacity_envelope(m, eMn_pos, eMn_neg, M)

    num_nodes = length(m)

    eMn_pos_all = [eMn_pos[m[i]] for i=1:num_nodes]
    eMn_neg_all = [eMn_neg[m[i]] for i=1:num_nodes]

    #Make sure the smaller capacity is taken at a discontinuity, like at the end of a splice.
    diff_m = diff(m)
    jumps = findall(x-> x > 0.0, diff_m)
    for i = 1:length(jumps)
        eMn_pos_all[jumps[i]] = minimum([eMn_pos_all[jumps[i]], eMn_pos_all[jumps[i]+1]])
        eMn_neg_all[jumps[i]] = minimum([eMn_neg_all[jumps[i]], eMn_neg_all[jumps[i]+1]])
    end


    eMn_all = zeros(Float64, num_nodes)

    for i in eachindex(M)

        if M[i] >= 0.0

            eMn_all[i] = eMn_pos_all[i]
            
        elseif M[i] < 0.0

            eMn_all[i] = eMn_neg_all[i]

        end

    end

    return eMn_all

end

function calculate_flexure_torsion_demand_to_capacity(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]
    num_nodes = length(purlin_line.model.z)

    eMnℓ_xx_pos_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_pos for i=1:num_purlin_segments]
    eMnℓ_xx_neg_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_neg for i=1:num_purlin_segments]
    eMnℓ_xx_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnℓ_xx_pos_range, eMnℓ_xx_neg_range, purlin_line.internal_forces.Mxx)

    eMnℓ_yy_pos_range = [purlin_line.local_global_flexural_strength_yy[i].eMnℓ_pos for i=1:num_purlin_segments]
    eMnℓ_yy_neg_range = [purlin_line.local_global_flexural_strength_yy[i].eMnℓ_neg for i=1:num_purlin_segments]
    eMnℓ_yy_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnℓ_yy_pos_range, eMnℓ_yy_neg_range, purlin_line.internal_forces.Myy)

    eBn_range = [purlin_line.torsion_strength[i].eBn for i=1:num_purlin_segments]
    eBn_all = zeros(Float64, num_nodes)
    eBn_all .= eBn_range[purlin_line.model.m]

    #There is no positive or negative capacity here because a first yield criteria is used to determine strength.  Local buckling is not considered.
    eMnℓ_yy_free_flange_range = [purlin_line.yielding_flexural_strength_free_flange_yy[i].eMy for i=1:num_purlin_segments]
    eMnℓ_yy_free_flange_all = zeros(Float64, num_nodes)
    eMnℓ_yy_free_flange_all .= eMnℓ_yy_free_flange_range[purlin_line.model.m]

    #Assume free flange bending interaction with strong axis flexure is in play only when there is negative moment.
    num_nodes = length(purlin_line.model.z)
    free_flange_moment = zeros(Float64, num_nodes)
    for i = 1:num_nodes
        if purlin_line.internal_forces.Mxx[i] < 0.0
            free_flange_moment[i] = purlin_line.free_flange_internal_forces.Myy[i]
        end
    end


    results = AISIS10024.h42.(purlin_line.internal_forces.Mxx, purlin_line.internal_forces.Myy, purlin_line.internal_forces.B, free_flange_moment, eMnℓ_xx_all, eMnℓ_yy_all, eBn_all, eMnℓ_yy_free_flange_all)

    action_Mx = [x[1] for x in results]
    action_My = [x[2] for x in results]
    action_B = [x[3] for x in results]
    action_My_freeflange = [x[4] for x in results]
    interaction = [x[5] for x in results]

    demand_to_capacity = interaction ./ 1.15   #Consider updating this 1.15 in the future based on AISI COS discussions.

    flexure_torsion_demand_to_capacity = FlexureTorsion_DemandToCapacity_Data(action_Mx, action_My, action_B, action_My_freeflange, interaction, demand_to_capacity)

    return flexure_torsion_demand_to_capacity, eMnℓ_xx_all, eMnℓ_yy_all, eBn_all, eMnℓ_yy_free_flange_all

end



#find distortional buckling D/C
function calculate_distortional_buckling_demand_to_capacity(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]
    eMnd_xx_pos_range = [purlin_line.distortional_flexural_strength_xx[i].eMnd_pos for i=1:num_purlin_segments]
    eMnd_xx_neg_range = [purlin_line.distortional_flexural_strength_xx[i].eMnd_neg for i=1:num_purlin_segments]
    eMnd_xx_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnd_xx_pos_range, eMnd_xx_neg_range, purlin_line.internal_forces.Mxx)

    #check distortional buckling
    distortional_demand_to_capacity = abs.(purlin_line.internal_forces.Mxx./eMnd_xx_all)

    return distortional_demand_to_capacity, eMnd_xx_all

end

#find flexure+shear D/C
function calculate_flexure_shear_demand_to_capacity(purlin_line)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]
    num_nodes = length(purlin_line.model.z)

    eMnℓ_xx_pos_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_pos for i=1:num_purlin_segments]
    eMnℓ_xx_neg_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_neg for i=1:num_purlin_segments]
    eMnℓ_xx_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnℓ_xx_pos_range, eMnℓ_xx_neg_range, purlin_line.internal_forces.Mxx)

    eVn_range = [purlin_line.shear_strength[i].eVn for i=1:num_purlin_segments]
    eVn_all = zeros(Float64, num_nodes)
    eVn_all .= eVn_range[purlin_line.model.m]

    flexure_shear_demand_to_capacity = AISIS10016.h21.(purlin_line.internal_forces.Mxx, purlin_line.internal_forces.Vyy, eMnℓ_xx_all, eVn_all)

    return flexure_shear_demand_to_capacity, eMnℓ_xx_all, eVn_all

end


#find biaxial bending D/C
function calculate_biaxial_bending_demand_to_capacity(purlin_line)

    #no axial force calculations for now.
    num_nodes = length(purlin_line.model.z)
    Pa=ones(Float64, num_nodes)

    num_purlin_segments = size(purlin_line.inputs.segments)[1]
    eMnℓ_xx_pos_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_pos for i=1:num_purlin_segments]
    eMnℓ_xx_neg_range = [purlin_line.local_global_flexural_strength_xx[i].eMnℓ_neg for i=1:num_purlin_segments]
    eMnℓ_xx_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnℓ_xx_pos_range, eMnℓ_xx_neg_range, purlin_line.internal_forces.Mxx)

    eMnℓ_yy_pos_range = [purlin_line.local_global_flexural_strength_yy[i].eMnℓ_pos for i=1:num_purlin_segments]
    eMnℓ_yy_neg_range = [purlin_line.local_global_flexural_strength_yy[i].eMnℓ_neg for i=1:num_purlin_segments]
    eMnℓ_yy_all = calculate_flexural_capacity_envelope(purlin_line.model.m, eMnℓ_yy_pos_range, eMnℓ_yy_neg_range, purlin_line.internal_forces.Myy)

    results = AISIS10016.h121.(purlin_line.internal_forces.P, purlin_line.internal_forces.Mxx, purlin_line.internal_forces.Myy, Pa, eMnℓ_xx_all, eMnℓ_yy_all)

    action_P = [x[1] for x in results]
    action_Mxx = [x[2] for x in results]
    action_Myy = [x[3] for x in results]
    interaction = [x[4] for x in results]

    demand_to_capacity = interaction

     #Grab all this info and put in a data structure.
     biaxial_bending_demand_to_capacity = BiaxialBending_DemandToCapacity_Data(action_P, action_Mxx, action_Myy, interaction, demand_to_capacity)

    return biaxial_bending_demand_to_capacity, eMnℓ_xx_all, eMnℓ_yy_all 

end

function calculate_support_reactions(support_locations, z, Vyy)

    num_supports = length(support_locations)
    num_nodes = length(z)

    Fyy = zeros(Float64, num_supports)

    for i = 1:num_supports

        support_index = findfirst(x->x≈support_locations[i], z)

        if support_index == 1  #z=0

            Fyy[i] = Vyy[support_index]
            
        elseif support_index == num_nodes  #z=end

            Fyy[i] = -Vyy[support_index]

        else  #interior supports

            Fyy[i] = -Vyy[support_index - 1] + Vyy[support_index]

        end


    end

    return Fyy

end


function calculate_web_crippling_demand_to_capacity(purlin_line)

    num_supports = length(purlin_line.inputs.support_locations)

    Fyy = calculate_support_reactions(purlin_line.inputs.support_locations, purlin_line.model.z, purlin_line.internal_forces.Vyy)

    purlin_line.support_reactions = Reactions(Fyy)

    DC = zeros(Float64, num_supports)

    for i = 1:num_supports

        if purlin_line.support_reactions.Fyy[i] <= 0.0

            DC[i] = 0.0   #uplift, no web crippling

        elseif purlin_line.inputs.purlin_frame_connections == "anti-roll clip"

            DC[i] = 0.0   #Assume anti-roll clip braces purlin web over flange

        else

            DC[i] = purlin_line.support_reactions.Fyy[i]/purlin_line.web_crippling[i].ePn

        end

    end

    return DC

end

function calculate_internal_forces(model)

    Mxx = StructuresKit.InternalForces.moment(model.z, model.m, -model.v, model.E, model.Ix)
    Myy = StructuresKit.InternalForces.moment(model.z, model.m, -model.u, model.E, model.Iy)
    Vxx = StructuresKit.InternalForces.shear(model.z, model.m, -model.u, model.E, model.Iy)
    Vyy = StructuresKit.InternalForces.shear(model.z, model.m, -model.v, model.E, model.Ix)
    T = StructuresKit.InternalForces.torsion(model.z, model.m, model.ϕ, model.E, model.G, model.J, model.Cw)
    B = StructuresKit.InternalForces.bimoment(model.z, model.m, model.ϕ, model.E, model.Cw)

    return Mxx, Myy, Vxx, Vyy, T, B

end

"""
    analysis(purlin_line)

Returns the PurlinLine structural response to an applied pressure.
"""

function analyze(purlin_line)

    #Translate purlin_line design variables to ThinWalledBeam design variables.
    z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports = PurlinLine.thin_walled_beam_interface(purlin_line)

    #Set up ThinWalledBeam model.
    model = ThinWalledBeam.define(z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports)

    #Solve ThinWalledBeam model.
    purlin_line.model = ThinWalledBeam.solve(model)

    #Calculate purlin line internal forces and moments from deformations, add them to data structure.
    Mxx, Myy, Vxx, Vyy, T, B = calculate_internal_forces(purlin_line.model)

    num_nodes = length(purlin_line.model.z)
    P = zeros(Float64, num_nodes)  #No axial force in purlin for now.  Could be added later.

    #Add internal forces to data structure.
    purlin_line.internal_forces = InternalForceData(P, Mxx, Myy, Vxx, Vyy, T, B)

    #Translate purlin_line design variables to BeamColumn design variables.
    z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, kH, hxf, hyf, axf, ayf, end_boundary_conditions, supports = beam_column_interface(purlin_line)

    #Calculate axial force in free flange.
    Pf = calculate_free_flange_axial_force(Mxx, member_definitions, purlin_line)

    #Apply the shear flow based on the y-direction load along the purlin line free flange model.
    qxf = qy .* kH

    #The y-direction load is assumed to be zero in the free flange model.
    num_nodes = length(z)
    qyf = zeros(Float64, num_nodes)

    #Set up the free flange model.
    purlin_line.free_flange_model = BeamColumn.define(z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, hxf, hyf, qxf, qyf, Pf, axf, ayf, end_boundary_conditions, supports)

    #Run the free flange model.
    purlin_line.free_flange_model = BeamColumn.solve(purlin_line.free_flange_model)

    #Calculate internal forces in the free flange.
    Mxx, Myy, Vxx, Vyy, T, B = calculate_internal_forces(purlin_line.free_flange_model)

    #Add free flange internal forces to data structure.
    purlin_line.free_flange_internal_forces = InternalForceData(Pf, Mxx, Myy, Vxx, Vyy, T, B)

    #Calculate demand-to-capacity ratios for each of the purlin line limit states.
    purlin_line.flexure_torsion_demand_to_capacity, eMnℓ_xx_all, eMnℓ_yy_all, eBn_all, eMnℓ_yy_free_flange_all = calculate_flexure_torsion_demand_to_capacity(purlin_line)
    purlin_line.distortional_demand_to_capacity, eMnd_xx_all = calculate_distortional_buckling_demand_to_capacity(purlin_line)
    purlin_line.flexure_shear_demand_to_capacity, eMnℓ_xx_all, eVn_all = calculate_flexure_shear_demand_to_capacity(purlin_line)        
    purlin_line.biaxial_bending_demand_to_capacity, eMnℓ_xx_all, eMnℓ_yy_all = calculate_biaxial_bending_demand_to_capacity(purlin_line)
    purlin_line.web_crippling_demand_to_capacity = calculate_web_crippling_demand_to_capacity(purlin_line)

    #Add expected strengths along purlin line to data structure.
    purlin_line.expected_strengths = ExpectedStrengths(eMnℓ_xx_all, eMnℓ_yy_all, eMnℓ_yy_free_flange_all, eMnd_xx_all, eVn_all, eBn_all)

    return purlin_line

end

function find_max_demand_to_capacity(purlin_line)

    max_demand_to_capacity_flexure_torsion = maximum(purlin_line.flexure_torsion_demand_to_capacity.demand_to_capacity)
    max_demand_to_capacity_distortional = maximum(purlin_line.distortional_demand_to_capacity)
    max_demand_to_capacity_flexure_shear = maximum(purlin_line.flexure_shear_demand_to_capacity)
    max_demand_to_capacity_biaxial_bending = maximum(purlin_line.biaxial_bending_demand_to_capacity.demand_to_capacity)
    max_demand_to_capacity_web_crippling = maximum(purlin_line.web_crippling_demand_to_capacity)

    max_demand_to_capacity = maximum([max_demand_to_capacity_flexure_torsion; max_demand_to_capacity_distortional; max_demand_to_capacity_flexure_shear; max_demand_to_capacity_biaxial_bending; max_demand_to_capacity_web_crippling])

    return max_demand_to_capacity

end


function identify_failure_limit_state(purlin_line)

    max_DC_location_index = Array{Int64}(undef, 5)

    max_DC_flexure_torsion = maximum(purlin_line.flexure_torsion_demand_to_capacity.demand_to_capacity)
    max_DC_location_index[1] = findfirst(x->x≈max_DC_flexure_torsion, purlin_line.flexure_torsion_demand_to_capacity.demand_to_capacity) 

    max_DC_distortional = maximum(purlin_line.distortional_demand_to_capacity)
    max_DC_location_index[2] = findfirst(x->x≈max_DC_distortional, purlin_line.distortional_demand_to_capacity) 

    max_DC_flexure_shear = maximum(purlin_line.flexure_shear_demand_to_capacity)
    max_DC_location_index[3] = findfirst(x->x≈max_DC_flexure_shear, purlin_line.flexure_shear_demand_to_capacity) 

    max_DC_biaxial_bending = maximum(purlin_line.biaxial_bending_demand_to_capacity.demand_to_capacity)
    max_DC_location_index[4] = findfirst(x->x≈max_DC_biaxial_bending, purlin_line.biaxial_bending_demand_to_capacity.demand_to_capacity) 

    max_DC_web_crippling = maximum(purlin_line.web_crippling_demand_to_capacity)
    max_DC_location_index[5] = findfirst(x->x≈max_DC_web_crippling, purlin_line.web_crippling_demand_to_capacity) 

    max_DC_list = [max_DC_flexure_torsion; max_DC_distortional; max_DC_flexure_shear; max_DC_biaxial_bending; max_DC_web_crippling]
    max_DC = maximum(max_DC_list)

    controlling_limit_state_index = findfirst(x->x≈max_DC, max_DC_list)

    if controlling_limit_state_index == 1

        controlling_limit_state = "strong axis flexure + weak axis flexure + lateral free flange deformation + torsion"

    elseif controlling_limit_state_index == 2

        controlling_limit_state = "distortional buckling"

    elseif controlling_limit_state_index == 3

        controlling_limit_state = "flexure + shear"

    elseif controlling_limit_state_index == 4

        controlling_limit_state = "biaxial bending"

    elseif controlling_limit_state_index == 5

        controlling_limit_state = "web crippling"

    end
    
    controlling_limit_state_location_index = max_DC_location_index[controlling_limit_state_index]

    if controlling_limit_state_index == "web crippling"

        failure_location = purlin_line.inputs.support[controlling_limit_state_location_index]

    else

        failure_location = purlin_line.model.z[controlling_limit_state_location_index]

    end

    return controlling_limit_state, failure_location

end

"""
    test(purlin_line)

Returns the PurlinLine failure pressure, failure location, and failure limit state.
"""

function test(purlin_line)

    DC_tolerance = 0.01  
    
    if purlin_line.loading_direction == "gravity"

        load_sign = 1.0
    
    elseif purlin_line.loading_direction =="uplift"
    
        load_sign = -1.0
    
    end

    #Run a very small pressure to get the test going.
    purlin_line.applied_pressure = load_sign * 10^-6
    purlin_line = PurlinLine.analyze(purlin_line)
    max_DC = find_max_demand_to_capacity(purlin_line)

    #Define initial residual.
    residual = 1.0 - abs(max_DC)

    while residual > DC_tolerance

        new_pressure = purlin_line.applied_pressure / max_DC
        purlin_line.applied_pressure = purlin_line.applied_pressure + (new_pressure - purlin_line.applied_pressure) / 2

        purlin_line = PurlinLine.analyze(purlin_line)
        max_DC = find_max_demand_to_capacity(purlin_line)

        residual = 1.0 - abs(max_DC)

    end

    purlin_line.failure_limit_state, purlin_line.failure_location = identify_failure_limit_state(purlin_line)

    return purlin_line

end

end # module
