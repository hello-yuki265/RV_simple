li  x1, 10
li  x2, 20
add x3, x1, x2
li  x4, 30
add s0, x3, x2
add s1, s0, x1

beq s0, s1, tag
li  s1, 30
j end
tag:
    li x1, 100
end:
    li x1, 200

li  s0, 100
li  s1, 200
bne s0, s1, tag0
li  s1, 30
j end0
tag0:
    li x1, 300
end0:
    li x1, 4000




        