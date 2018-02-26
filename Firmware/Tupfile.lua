
tup.include('build.lua')

boarddir = 'Board/v3.3'


-- C-specific flags
FLAGS += '-D__weak="__attribute__((weak))"'
FLAGS += '-D__packed="__attribute__((__packed__))"'
FLAGS += '-DUSE_HAL_DRIVER'
FLAGS += '-DSTM32F405xx'

FLAGS += '-mthumb'
FLAGS += '-mcpu=cortex-m4'
FLAGS += '-mfpu=fpv4-sp-d16'
FLAGS += '-mfloat-abi=hard'
FLAGS += { '-Wall', '-fdata-sections', '-ffunction-sections'}

if tup.getconfig('DEBUG') == 'y' then
    --C_FLAGS += '-g -gdwarf-2'
    FLAGS += '-g -gdwarf-2'
end

-- linker flags
LDFLAGS += '-T'..boarddir..'/STM32F405RGTx_FLASH.ld'
LDFLAGS += '-L'..boarddir..'/Drivers/CMSIS/Lib' -- lib dir
LDFLAGS += '-lc -lm -lnosys -larm_cortexM4lf_math' -- libs
LDFLAGS += '-mthumb -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -specs=nosys.specs -specs=nano.specs -u _printf_float -u _scanf_float -Wl,--cref -Wl,--gc-sections'


-- common flags for ASM, C and C++
OPT += '-Og'
OPT += '-ffast-math'
tup.append_table(FLAGS, OPT)
tup.append_table(LDFLAGS, OPT)

toolchain = GCCToolchain('arm-none-eabi-', 'build', FLAGS, LDFLAGS)


-- Load list of source files Makefile that was autogenerated by CubeMX
vars = parse_makefile_vars(boarddir..'/Makefile')
all_stm_sources = (vars['C_SOURCES'] or '')..' '..(vars['CPP_SOURCES'] or '')..' '..(vars['ASM_SOURCES'] or '')
for src in string.gmatch(all_stm_sources, "%S+") do
    stm_sources += boarddir..'/'..src
end
for src in string.gmatch(vars['C_INCLUDES'] or '', "%S+") do
    stm_includes += boarddir..'/'..string.sub(src, 3, -1) -- remove "-I" from each include path
end

stm_includes += 'MotorControl'
build{
    name='stm_platform',
    type='objects',
    toolchains={toolchain},
    packages={},
    sources=stm_sources,
    includes=stm_includes
}

build{
    name='ODriveFirmware',
    toolchains={toolchain},
    --toolchains={LLVMToolchain('x86_64', {'-Ofast'}, {'-flto'})},
    packages={'stm_platform'},
    sources={
        'MotorControl/utils.c',
        'MotorControl/legacy_commands.c',
        'MotorControl/low_level.c',
        'MotorControl/nvm.c',
        'MotorControl/axis.cpp',
        'MotorControl/commands.cpp',
        'MotorControl/protocol.cpp',
        'MotorControl/config.cpp'
    },
    includes={
        'MotorControl'
    }
}
