-- A chunk just moves forward in a dumb way, and contains a series of blocks
-- depending on the difficulty assigned to this chunk, the cubes spawned to jump on will be different
-- Chunks shall be no wider than 8 blocks wide and no longer than 8 blocks long
-- The chunk scenes are as follows:
	--0 : Flat ground, all cubes
	--1 : Flat ground with two bars of 3 block wide on each side
	--2 : Random 2-block wide 
	--3 : 
	--4 : Random 2-block wide 
	--5 : Two staggered 2x4 islands, each with , one a single block behind the other
	--6 : 
	--7 : Single 2x2 island, one block higher up.
chunkCtrl = {}

-- Chunks' start positions are set by the gameCtrl
function chunkCtrl:Create()
	self:GetMaterial():SetUvOffset(Vec(5.5,0.5))
	Log.Warning("Done")
	Log.Warning(self:GetMaterial():GetUvOffset().x)
end