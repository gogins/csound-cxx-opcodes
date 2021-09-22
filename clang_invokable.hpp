#pragma once

#include <csdl.h>

/**
 * Defines the pure bstract interface implemented by Clang modules to be 
 * called by Csound using the `clang_invoke` opcode.
 */
struct ClangInvokable {
	virtual ~ClangInvokable() = 0;
	/**
	 * Called once at init time. The inputs are the same as the 
	 * parameters passed to the `clang_invoke` opcode. The outputs become 
	 * the values returned from the `clang_invoke` opcode. Performs the 
	 * same work as `iopadr` in a standard Csound opcode definition. The 
	 * `opds` argument can be used to find many things about the invoking 
     * opcde and its enclosing instrument.
	 */
	virtual int init(CSOUND *csound, const OPDS *opds, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called once every kperiod. The inputs are the same as the 
	 * parameters passed to the `clang_invoke` opcode. The outputs become 
	 * the values returned from the `clang_invoke` opcode. Performs the 
	 * same work as `kopadr` in a standard Csound opcode definition.
	 */
	virtual int kontrol(CSOUND *csound, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called by Csound when the Csound instrument that contains this 
	 * instance of the ClangInvokable is turned off.
	 */
	virtual int noteoff(CSOUND *csound) = 0;
};

/**
 * Concrete base class that implements `ClangInvokable`, with some helper 
 * facilities. Most users will implement a ClangInvokable by inheriting from 
 * `ClangInvokableBase` and overriding one or more of its virtual methods.
 */
class ClangInvokableBase : public ClangInvokable {
    public:
        virtual ~ClangInvokableBase() {};
        virtual int init(CSOUND *csound_, const OPDS *opds_, MYFLT **outputs, MYFLT **inputs) {
            int result = OK;
            csound = csound_;
            // Make a flat copy of the invoking opcode's OPDS header.
            std::memcpy(&opds, opds_, sizeof(OPDS));
            return result;
        }
        virtual int kontrol(CSOUND *csound_, MYFLT **outputs, MYFLT **inputs) {
            int result = OK;
            return result;
        }
        virtual int noteoff(CSOUND *csound) 
        {
            int result = OK;
            return result;
        }
        uint32_t kperiodOffset() const
        {
            return opds.insdshead->ksmps_offset;
        }
        uint32_t kperiodEnd() const
        {
            uint32_t end = opds.insdshead->ksmps_no_end;
            if (end) {
                return end;
            } else {
                return ksmps();
            }
        }
        uint32_t ksmps() const
        {
            return opds.insdshead->ksmps;
        }
        uint32_t output_arg_count()
        {
            return (uint32_t)opds.optext->t.outArgCount;
        }
        uint32_t input_arg_count()
        {
            return (uint32_t)opds.optext->t.inArgCount;
        }
        void log(const char *format,...)
        {
            va_list args;
            va_start(args, format);
            if(csound) {
                csound->MessageV(csound, 0, format, args);
            } else {
                vfprintf(stdout, format, args);
            }
            va_end(args);
        }
        void warn(const char *format,...)
        {
            if(csound) {
                if(csound->GetMessageLevel(csound) & WARNMSG) {
                    va_list args;
                    va_start(args, format);
                    csound->MessageV(csound, CSOUNDMSG_WARNING, format, args);
                    va_end(args);
                }
            } else {
                va_list args;
                va_start(args, format);
                vfprintf(stdout, format, args);
                va_end(args);
            }
        }
    protected:
        OPDS opds;
        CSOUND *csound = nullptr;
};