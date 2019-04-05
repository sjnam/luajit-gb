local ffi = require "ffi"
local gb_graph = require "gb.graph"
local gb_io = require "gb.io" 
local gb_basic = require "gb.basic" 
local gb_books = require "gb.books" 
local gb_econ = require "gb.econ" 
local gb_games = require "gb.games" 
local gb_gates = require "gb.gates" 
local gb_lisa = require "gb.lisa" 
local gb_miles = require "gb.miles" 
local gb_plane = require "gb.plane" 
local gb_raman = require "gb.raman" 
local gb_rand = require "gb.rand" 
local gb_roget = require "gb.roget" 
local gb_save = require "gb.save" 
local gb_words = require "gb.words" 
local NULL = ffi.null
local str = ffi.string
local byte = string.byte
local io_write = io.write
local econ = gb_econ.econ
local book = gb_books.book
local games = gb_games.games
local miles = gb_miles.miles
local words = gb_words.words
local raman = gb_raman.raman
local random_graph = gb_rand.random_graph
local random_lengths = gb_rand.random_lengths
local random_bigraph = gb_rand.random_bigraph
local board = gb_basic.board
local gunion = gb_basic.gunion
local subsets = gb_basic.subsets
local complement = gb_basic.complement
local save_graph = gb_save.save_graph
local restore_graph = gb_save.restore_graph
local gb_recycle = gb_graph.gb_recycle
local gb_typed_alloc = gb_graph.gb_typed_alloc
local gb_save_string = gb_graph.gb_save_string
local plane_lisa = gb_lisa.plane_lisa
local plane_miles = gb_plane.plane_miles
local roget = gb_roget.roget
local risc = gb_gates.risc
local partial_gates = gb_gates.partial_gates


local gb = ffi.load "gb"


local function printf (...)
   io_write(string.format(...))
end


local pr_vert, pr_arc, pr_util


local function print_sample (g, n)
   print()
   if g == NULL then
      print("Ooops, we just ran into panic code "..tonumber(gb.panic_code).."!")
      if tonumber(gb.io_errors) ~= 0 then
         print("(The I/O error code is 0x"..gb_io.io_errors)
      end
   else
      printf("\"%s\"\n%d vertices, %d arcs, util_types %s",
             str(g.id), tonumber(g.n), tonumber(g.m), str(g.util_types))
      pr_util(g.uu, g.util_types[8], 0, g.util_types)
      pr_util(g.vv, g.util_types[9], 0, g.util_types)
      pr_util(g.ww, g.util_types[10], 0, g.util_types)
      pr_util(g.xx, g.util_types[11], 0, g.util_types)
      pr_util(g.yy, g.util_types[12], 0, g.util_types)
      pr_util(g.zz, g.util_types[13], 0, g.util_types)
      print()

      io_write("V"..n..": ")
      if n >= g.n or n < 0 then
         print("index is out of range!")
      else
         pr_vert(g.vertices+n, 1, g.util_types)
         print()
      end
      gb_recycle(g)
   end
end


pr_vert = function (v, l, s)
   if v == NULL then
      io_write("NULL")
   elseif gb_gates.is_boolean(v) then
      io_write("ONE")
   else
      io_write("\""..str(v.name).."\"")
      pr_util(v.u, s[0], l-1, s)
      pr_util(v.v, s[1], l-1, s)
      pr_util(v.w, s[2], l-1, s)
      pr_util(v.x, s[3], l-1, s)
      pr_util(v.y, s[4], l-1, s)
      pr_util(v.z, s[5], l-1, s)
      if l > 0 then
         local a = v.arcs
         while a ~= NULL do
            io_write("\n   ")
            pr_arc(a, 1, s)
            a = a.next
         end
      end
   end
end


pr_arc = function (a, l, s)
   io_write("->");
   pr_vert(a.tip, 0, s);
   if l > 0 then
      io_write(", "..tonumber(a.len))
      pr_util(a.a, s[6], l-1, s)
      pr_util(a.b, s[7], l-1, s)
   end
end


pr_util = function (u, c, l, s)
   if c == byte('I') then
      printf("[%d]", tonumber(u.I))
   elseif c == byte('S') then
      printf("[\"%s\"]", u.S ~= NULL and ffi.string(u.S) or "(null)")
   elseif c == byte('A') then
      if l < 0 then return end
      io_write("[");
      if u.A == NULL then
         io_write("NULL")
      else
         pr_arc(u.A, l, s)
      end
      io_write("]")
   elseif c == byte('V') then
      if l < 0 then return end
      io_write("[")
      pr_vert(u.V, l, s)
      io_write("]")
   end
end


-- main
local dst = ffi.new("long[3]", {0x20000000,0x10000000,0x10000000})
local wt_vec = ffi.new("long[9]",
                       {100,-80589,50000,18935,-18935,18935,18935,18935,18935})

print("GraphBase samples generated by test_sample:")

local g = random_graph(3, 10, 1, 1, 0, NULL, dst, 1, 2, 1)
local gg = complement(g, 1, 1, 0)
local v = ffi.cast("Vertex*", gb_typed_alloc(1, "Vertex", gg.data))
v.name = gb_save_string("Testing")
gg.util_types[10] = byte("V")
gg.ww.V = v
save_graph(gg, "test.gb")
gb_recycle(g)
gb_recycle(gg)

print_sample(raman(31, 3, 0, 4), 4)

print_sample(board(1, 1, 2, -33, 1, -0x40000000-0x40000000, 1), 2000)

print_sample(subsets(32, 18, 16, 0, 999, -999, 0x80000000, 1), 1)

g = restore_graph("test.gb");
local i = random_lengths(g, 0, 10, 12, dst, 2)
if i ~= 0 then
   printf("\nFailure code %d returned by random_lengths!\n", i)
else
   gg = random_graph(3, 10, 1, 1, 0, NULL, dst, 1, 2, 1)
   print_sample(gunion(g, gg, 1, 0), 2)
   gb_recycle(g)
   gb_recycle(gg)
end

print_sample(partial_gates(risc(0), 1, 43210, 98765, NULL), 79)

print_sample(book("homer", 500, 400, 2, 12, 10000, -123456, 789),81)
print_sample(econ(40, 0, 400, -111), 11)
print_sample(games(60 ,70, 80, -90, -101, 60, 0,999999999), 14)
print_sample(miles(50, -500, 100, 1, 500, 5, 314159), 20)
print_sample(plane_lisa(100, 100, 50, 1, 300, 1, 200,
                        50*299*199, 200*299*199), 1294)
print_sample(plane_miles(50 ,500, -100, 1, 1, 40000, 271818), 14)
print_sample(random_bigraph(300, 3, 1000, -1, NULL, dst, -500, 500, 666), 3)
print_sample(roget(1000, 3, 1009, 1009), 40)

print_sample(words(100, wt_vec, 70000000, 69), 5)
wt_vec[1] = wt_vec[1] + 1
print_sample(words(100, wt_vec, 70000000, 69), 5)
print_sample(words(0, NULL, 0, 69), 5555)