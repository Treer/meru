-- meru 0.2.0 by paramat.
-- License WTFPL.

-- Parameters.

local ONGEN = true -- (true / false) Enable / disable generation.
local PROG = true -- Print processing progess to terminal.
local COORD = false -- Print tower co-ordinates to terminal.

local XMIN = -1024 -- Area for random spawn.
local XMAX = 1024
local ZMIN = -1024
local ZMAX = 1024

local BASRAD = 64 --  -- Average radius y = -32.
local HEIGHT = 1024 --  -- Approximate height measured from y = -32.
local CONVEX = 0.6 --  -- Convexity. 0.5 = concave, 1 = perfect cone, 2 = convex.
local VOID = 0.4 --  -- Void threshold. Controls size of central voids. 
local NOISYRAD = 0.2 --  -- Noisyness of structure at base radius. 0 = smooth geometric form, 0.3 = noisy.
local NOISYCEN = 0 --  -- Noisyness of structure at centre.
local FISOFFBAS = 0.02 --  -- Fissure noise offset at base. controls amount / size of fissure entrances on outer surface.
local FISOFFTOP = 0.04 --  -- Fissure noise offset at top.
local FISEXPBAS = 0.6 --  -- Fissure expansion rate under surface at base.
local FISEXPTOP = 1.2 --  -- Fissure expansion rate under surface at top.

local SEEDDIFF1 = 46893 -- 3D noise for primary structure.
local OCTAVES1 = 5 -- 
local PERSISTENCE1 = 0.5 -- 
local SCALE1 = 64 -- 

local SEEDDIFF2 = 92940980987 -- 3D noise for fissures.
local OCTAVES2 = 4 -- 
local PERSISTENCE2 = 0.5 -- 
local SCALE2 = 24 -- 

-- End of parameters.

meru = {}

local SEEDDIFF3 = 9130 -- 9130 -- Values should match minetest mapgen desert perlin.
local OCTAVES3 = 3 -- 3
local PERSISTENCE3 = 0.5 -- 0.5
local SCALE3 = 250 -- 250

local SEEDDIFF4 = 5839090
local OCTAVES4 = 2 -- 2
local PERSISTENCE4 = 0.5 -- 0.5
local SCALE4 = 3 -- 3

local cxmin = math.floor((XMIN + 32) / 80) -- chunk co ordinates
local czmin = math.floor((ZMIN + 32) / 80)
local cxmax = math.floor((XMAX + 32) / 80)
local czmax = math.floor((ZMAX + 32) / 80)
local cxav = (cxmin + cxmax) / 2
local czav = (czmin + czmax) / 2
local xnom = (cxmax - cxmin) / 4
local znom = (czmax - czmin) / 4

-- On generated function.

if ONGEN then
	minetest.register_on_generated(function(minp, maxp, seed)
		if maxp.x >= XMIN and minp.x <= XMAX
		and maxp.z >= ZMIN and minp.z <= ZMAX then
			local env = minetest.env
			local perlin4 = env:get_perlin(SEEDDIFF4, OCTAVES4, PERSISTENCE4, SCALE4)
			local noisex = perlin4:get2d({x=31,y=23})
			local noisez = perlin4:get2d({x=17,y=11})
			local cx = cxav + math.floor(noisex * xnom) -- chunk co ordinates
			local cz = czav + math.floor(noisez * znom)
			local merux = 80 * cx + 8
			local meruz = 80 * cz + 8
			if COORD then
				print ("[meru] x "..merux.." z "..meruz)
			end
			if minp.x >= merux - 120 and minp.x <= merux + 40
			and minp.z >= meruz - 120 and minp.z <= meruz + 40
			and minp.y >= -32 and minp.y <= HEIGHT * 1.2 then
				local perlin1 = env:get_perlin(SEEDDIFF1, OCTAVES1, PERSISTENCE1, SCALE1)
				local perlin2 = env:get_perlin(SEEDDIFF2, OCTAVES2, PERSISTENCE2, SCALE2)
				local perlin3 = env:get_perlin(SEEDDIFF3, OCTAVES3, PERSISTENCE3, SCALE3)
				local x1 = maxp.x
				local y1 = maxp.y
				local z1 = maxp.z
				local x0 = minp.x
				local y0 = minp.y
				local z0 = minp.z
				-- Loop through nodes in chunk.
				for x = x0, x1 do
					-- For each plane do.
					if PROG then
						print ("[meru] Plane "..x - x0.." Chunk ("..minp.x.." "..minp.y.." "..minp.z..")")
					end
					for z = z0, z1 do
						-- For each column do.
						local noise3 = perlin3:get2d({x=x+150,y=z+50}) -- Offsets must match minetest mapgen desert perlin.
						local desert = false
						if noise3 > 0.45 or math.random(0,10) > (0.45 - noise3) * 100 then -- Smooth transition 0.35 to 0.45.
							desert = true 
						end
						for y = y0, y1 do
							-- For each node do.
							local noise1 = perlin1:get3d({x=x,y=y,z=z})
							local radius = ((x - merux) ^ 2 + (z - meruz) ^ 2) ^ 0.5
							local deprop = (BASRAD - radius) / BASRAD
							local noisy = NOISYRAD + deprop * (NOISYCEN - NOISYRAD)
							local heprop = ((y + 32) / HEIGHT)
	 						local offset = deprop - heprop ^ CONVEX
							local noise1off = noise1 * noisy + offset
							if noise1off > 0 and noise1off < VOID then
								local noise2 = perlin2:get3d({x=x,y=y,z=z})
								local fisoff = FISOFFBAS + heprop * (FISOFFTOP - FISOFFBAS)
								local fisexp = FISEXPBAS + heprop * (FISEXPTOP - FISEXPBAS)
								if math.abs(noise2) - noise1off * fisexp - fisoff > 0 then
									if desert then
										env:add_node({x=x,y=y,z=z},{name="default:desert_stone"})
									else
										env:add_node({x=x,y=y,z=z},{name="default:stone"})
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end
