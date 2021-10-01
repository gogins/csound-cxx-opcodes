#pragma once

#include <csdl.h>
#include <cstring>

/**
 * Author: Michael Gogins
 * https://github.com/gogins
 * http://michaelgogins.tumblr.com
 * 
 * This file is licensed by the GNU Lesser General Public License, version 2.1.
 *
 * Defines the pure abstract interface implemented by Clang modules to be 
 * called by Csound using the `clang_invoke` opcode.
 */
struct ClangInvokable {
	virtual ~ClangInvokable() {};
	/**
	 * Called once at init time. The inputs are the same as the 
	 * parameters passed to the `clang_invoke` opcode. The outputs become 
	 * the values returned from the `clang_invoke` opcode. Performs the 
	 * same work as `iopadr` in a standard Csound opcode definition. The 
	 * `opds` argument can be used to find many things about the invoking 
	 * opcode and its enclosing instrument.
	 */
	virtual int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) = 0;
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
        virtual ~ClangInvokableBase() {
        };
        int init(CSOUND *csound_, OPDS *opds_, MYFLT **outputs, MYFLT **inputs) override {
            int result = OK;
            csound = csound_;
            opds = opds_;
            return result;
        }
        int kontrol(CSOUND *csound_, MYFLT **outputs, MYFLT **inputs) override {
            int result = OK;
            return result;
        }
        int noteoff(CSOUND *csound) override 
        {
            int result = OK;
            return result;
        }
        uint32_t kperiodOffset() const
        {
            return opds->insdshead->ksmps_offset;
        }
        uint32_t kperiodEnd() const
        {
            uint32_t end = opds->insdshead->ksmps_no_end;
            if (end) {
                return end;
            } else {
                return ksmps();
            }
        }
        uint32_t ksmps() const
        {
            return opds->insdshead->ksmps;
        }
        uint32_t output_arg_count()
        {
            return (uint32_t)opds->optext->t.outArgCount;
        }
        uint32_t input_arg_count()
        {
            // The first two input arguments belong to the invoking opcode.
            return (uint32_t)opds->optext->t.inArgCount - 2;
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
        OPDS *opds = nullptr;
        CSOUND *csound = nullptr;
};
