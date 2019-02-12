module PictureSegmentation

using Images
using Makie
using ColorVectorSpace

abstract type SegmentationAlgorithm end
struct GrowCut <: SegmentationAlgorithm end

include("common.jl")
include("seedpixel.jl")
include("growcut.jl")
include("growcut3d.jl")
include("display.jl")

export
	# main functions
	segment_image,
	set_seed_pixels!,
	GrowCut,
	display_3d,
	help_rule_template,
	create_rule,
	convert_labels,
	make_contour
end # module
