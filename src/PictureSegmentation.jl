module PictureSegmentation

using Images
using Makie
using ColorVectorSpace

abstract type SegmentationAlgorithm end
struct GrowCut <: SegmentationAlgorithm end

include("seedpixel.jl")
include("growcut.jl")

export
	# main functions
	segment_image,
	set_seed_pixels,
	GrowCut
end # module
