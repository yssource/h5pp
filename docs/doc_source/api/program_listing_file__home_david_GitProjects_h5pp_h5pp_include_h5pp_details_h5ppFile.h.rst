
.. _program_listing_file__home_david_GitProjects_h5pp_h5pp_include_h5pp_details_h5ppFile.h:

Program Listing for File h5ppFile.h
===================================

|exhale_lsh| :ref:`Return to documentation for file <file__home_david_GitProjects_h5pp_h5pp_include_h5pp_details_h5ppFile.h>` (``/home/david/GitProjects/h5pp/h5pp/include/h5pp/details/h5ppFile.h``)

.. |exhale_lsh| unicode:: U+021B0 .. UPWARDS ARROW WITH TIP LEFTWARDS

.. code-block:: cpp

   
   #pragma once
   
   #include "h5ppConstants.h"
   #include "h5ppDimensionType.h"
   #include "h5ppEigen.h"
   #include "h5ppEnums.h"
   #include "h5ppFilesystem.h"
   #include "h5ppHdf5.h"
   #include "h5ppHid.h"
   #include "h5ppLogger.h"
   #include "h5ppOptional.h"
   #include "h5ppPropertyLists.h"
   #include "h5ppScan.h"
   #include "h5ppTypeCompoundCreate.h"
   #include "h5ppUtils.h"
   #include <hdf5.h>
   #include <hdf5_hl.h>
   #include <string>
   #include <utility>
   
   namespace h5pp {
   
       class File {
           private:
           fs::path             filePath; 
           h5pp::FilePermission permission   = h5pp::FilePermission::RENAME;
           size_t               logLevel     = 2;
           bool                 logTimestamp = false;
           hid::h5e             error_stack;
           unsigned int         currentCompressionLevel = 0;
           void                 init() {
               h5pp::logger::setLogger("h5pp|init", logLevel, logTimestamp);
               h5pp::logger::log->debug("Initializing HDF5 file: [{}]", filePath.string());
               /* Set default error print output */
               error_stack                          = H5Eget_current_stack();
               herr_t turnOffAutomaticErrorPrinting = H5Eset_auto2(error_stack, nullptr, nullptr);
               if(turnOffAutomaticErrorPrinting < 0) {
                   H5Eprint(H5E_DEFAULT, stderr);
                   throw std::runtime_error("Failed to turn off H5E error printing");
               }
               // The following function can modify the resulting filePath depending on permission.
               filePath = h5pp::hdf5::createFile(filePath, permission, plists);
               h5pp::type::compound::initTypes();
               h5pp::logger::setLogger("h5pp|" + filePath.filename().string(), logLevel, logTimestamp);
               h5pp::logger::log->debug("Successfully initialized file [{}]", filePath.string());
           }
   
           public:
           // The following struct contains modifiable property lists.
           // This allows us to use h5pp with MPI, for instance.
           // Unmodified, these default to serial (non-MPI) use.
           // We expose these property lists here so the user may set them as needed.
           // To enable MPI, the user can call H5Pset_fapl_mpio(hid_t file_access_plist, MPI_Comm comm, MPI_Info info)
           // The user is responsible for linking to MPI and learning how to set properties for MPI usage
           PropertyLists plists;
   
           File() {
               h5pp::logger::setLogger("h5pp", logLevel, logTimestamp);
               h5pp::logger::log->debug("Default-constructing h5pp file object");
           }
   
           File(const File &other) {
               h5pp::logger::log->debug("Copy-constructing this file [{}] from given file: [{}]", filePath.string(), other.getFilePath());
               *this = other;
           }
   
           explicit File(const std::string &filePath_, h5pp::FilePermission permission_ = h5pp::FilePermission::RENAME, size_t logLevel_ = 2, bool logTimestamp_ = false)
               : filePath(filePath_), permission(permission_), logLevel(logLevel_), logTimestamp(logTimestamp_) {
               init();
           }
   
           explicit File(const std::string &filePath_, unsigned int H5F_ACC_FLAGS, size_t logLevel_ = 2, bool logTimestamp_ = false)
               : filePath(filePath_), logLevel(logLevel_), logTimestamp(logTimestamp_) {
               permission = h5pp::hdf5::convertFileAccessFlags(H5F_ACC_FLAGS);
               init();
           }
   
           ~File() {
               h5pp::logger::log->debug("Closing file [{}]", filePath.string());
               H5garbage_collect();
               H5Eprint(H5E_DEFAULT, stderr);
           }
   
           File &operator=(const File &other) {
               h5pp::logger::log->debug("Assignment to this file [{}] from given file: [{}]", filePath.string(), other.getFilePath());
               if(&other != this) {
                   logLevel     = other.logLevel;
                   logTimestamp = other.logTimestamp;
                   permission   = other.permission;
                   filePath     = other.filePath;
                   plists       = other.plists;
                   h5pp::logger::setLogger("h5pp|" + filePath.filename().string(), logLevel, logTimestamp);
               }
               return *this;
           }
   
           void flush() {
               h5pp::logger::log->trace("Flushing caches");
               H5Fflush(openFileHandle(), H5F_scope_t::H5F_SCOPE_GLOBAL);
               H5garbage_collect();
               H5Eprint(H5E_DEFAULT, stderr);
           }
   
           [[nodiscard]] hid::h5f openFileHandle() const {
               h5pp::logger::setLogger("h5pp|" + filePath.filename().string(), logLevel, logTimestamp);
               if(permission == h5pp::FilePermission::READONLY) {
                   h5pp::logger::log->trace("Opening file in READONLY mode");
                   hid_t fileHandle = H5Fopen(filePath.string().c_str(), H5F_ACC_RDONLY, plists.fileAccess);
                   if(fileHandle < 0) {
                       H5Eprint(H5E_DEFAULT, stderr);
                       throw std::runtime_error(h5pp::format("Failed to open file in read-only mode [{}]", filePath.string()));
                   } else
                       return fileHandle;
               } else {
                   h5pp::logger::log->trace("Opening file in READWRITE mode");
                   hid_t fileHandle = H5Fopen(filePath.string().c_str(), H5F_ACC_RDWR, plists.fileAccess);
                   if(fileHandle < 0) {
                       H5Eprint(H5E_DEFAULT, stderr);
                       throw std::runtime_error(h5pp::format("Failed to open file in read-write mode [{}]", filePath.string()));
                   } else
                       return fileHandle;
               }
           }
   
           /*
            *
            * Functions for file properties
            *
            */
           [[nodiscard]] h5pp::FilePermission getFilePermission() const { return permission; }
           [[nodiscard]] std::string          getFileName() const { return filePath.filename().string(); }
           [[nodiscard]] std::string          getFilePath() const { return filePath.string(); }
           void                               setFilePermission(h5pp::FilePermission permission_) { permission = permission_; }
   
           void setDriver_sec2() {
               plists.fileAccess = H5Fget_access_plist(openFileHandle());
               H5Pset_fapl_sec2(plists.fileAccess);
           }
           void setDriver_stdio() {
               plists.fileAccess = H5Fget_access_plist(openFileHandle());
               H5Pset_fapl_stdio(plists.fileAccess);
           }
           void setDriver_core(bool writeOnClose = true, size_t bytesPerMalloc = 10240000) {
               plists.fileAccess = H5Fget_access_plist(openFileHandle());
               H5Pset_fapl_core(plists.fileAccess, bytesPerMalloc, static_cast<hbool_t>(writeOnClose));
           }
   #ifdef H5_HAVE_PARALLEL
           void setDriver_mpio(MPI_Comm comm, MPI_Info info) {
               plists.fileAccess = H5Fget_access_plist(openFileHandle());
               H5Pset_fapl_mpio(plists.fileAccess, comm, info);
           }
   #endif
   
           /*
            *
            * Functions for managing file location
            *
            */
   
           [[maybe_unused]] fs::path copyFileTo(const std::string &targetFilePath, const FilePermission &perm = FilePermission::COLLISION_FAIL) const {
               return h5pp::hdf5::copyFile(getFilePath(), targetFilePath, perm, plists);
           }
   
           [[maybe_unused]] fs::path moveFileTo(const std::string &targetFilePath, const FilePermission &perm = FilePermission::COLLISION_FAIL) {
               auto newPath = h5pp::hdf5::moveFile(getFilePath(), targetFilePath, perm, plists);
               if(fs::exists(newPath)) { filePath = newPath; }
               return newPath;
           }
   
           /*
            *
            * Functions for transfering contents between locations or files
            *
            */
   
           void copyLinkToFile(const std::string &   localLinkPath,
                               const std::string &   targetFilePath,
                               const std::string &   targetLinkPath,
                               const FilePermission &targetFileCreatePermission = FilePermission::READWRITE) const {
               return h5pp::hdf5::copyLink(getFilePath(), localLinkPath, targetFilePath, targetLinkPath, targetFileCreatePermission, plists);
           }
   
           void copyLinkFromFile(const std::string &localLinkPath, const std::string &sourceFilePath, const std::string &sourceLinkPath) {
               return h5pp::hdf5::copyLink(sourceFilePath, sourceLinkPath, getFilePath(), localLinkPath, h5pp::FilePermission::READWRITE, plists);
           }
   
           template<typename h5x_tgt, typename = h5pp::type::sfinae::enable_if_is_h5_loc<h5x_tgt>>
           void copyLinkToLocation(const std::string &localLinkPath, const h5x_tgt &targetLocationId, const std::string &targetLinkPath) const {
               return h5pp::hdf5::copyLink(openFileHandle(), localLinkPath, targetLocationId, targetLinkPath, plists);
           }
   
           template<typename h5x_src, typename = h5pp::type::sfinae::enable_if_is_h5_loc<h5x_src>>
           void copyLinkFromLocation(const std::string &localLinkPath, const h5x_src &sourceLocationId, const std::string &sourceLinkPath) {
               return h5pp::hdf5::copyLink(sourceLocationId, sourceLinkPath, openFileHandle(), localLinkPath, h5pp::FilePermission::READWRITE, plists);
           }
   
           /*
            *
            * Functions for logging
            *
            */
           [[nodiscard]] size_t getLogLevel() const { return logLevel; }
           void                 setLogLevel(size_t logLevelZeroToFive) {
               logLevel = logLevelZeroToFive;
               h5pp::logger::setLogLevel(logLevelZeroToFive);
           }
   
           /*
            *
            * Functions related to datasets
            *
            */
   
           void setCompressionLevel(unsigned int compressionLevelZeroToNine) { currentCompressionLevel = h5pp::hdf5::getValidCompressionLevel(compressionLevelZeroToNine); }
           [[nodiscard]] unsigned int getCompressionLevel() const { return currentCompressionLevel; }
           [[nodiscard]] unsigned int getCompressionLevel(std::optional<unsigned int> desiredCompressionLevel) const {
               if(desiredCompressionLevel)
                   return h5pp::hdf5::getValidCompressionLevel(desiredCompressionLevel.value());
               else
                   return currentCompressionLevel;
           }
   
           void createGroup(std::string_view group_relative_name) { h5pp::hdf5::createGroup(openFileHandle(), group_relative_name, std::nullopt, plists); }
   
           void resizeDataset(DsetInfo &info, const DimsType &newDimensions, std::optional<h5pp::ResizeMode> mode_override = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to resize dataset on read-only file [{}]", filePath.string()));
               h5pp::hdf5::resizeDataset(info, newDimensions, mode_override);
           }
   
           template<typename DsetDimsType = std::initializer_list<hsize_t>, typename = h5pp::type::sfinae::enable_if_is_integral_iterable_or_num<DsetDimsType>>
           DsetInfo resizeDataset(std::string_view dsetPath, const DsetDimsType &newDimensions, std::optional<h5pp::ResizeMode> mode = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to resize dataset on read-only file [{}]", filePath.string()));
               Options options;
               options.linkPath   = dsetPath;
               options.resizeMode = mode;
               auto info          = h5pp::scan::getDsetInfo(openFileHandle(), dsetPath, options, plists);
               if(not info.dsetExists.value()) throw std::runtime_error(h5pp::format("Failed to resize dataset [{}]: dataset does not exist", dsetPath));
               h5pp::hdf5::resizeDataset(info, h5pp::util::getDimVector(newDimensions), mode);
               return info;
           }
   
           void createDataset(DsetInfo &info) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create dataset on read-only file [{}]", filePath.string()));
               h5pp::hdf5::createDataset(info, plists);
           }
   
           DsetInfo createDataset(const Options &options) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create dataset on read-only file [{}]", filePath.string()));
               options.assertWellDefined();
               if(not options.linkPath) throw std::runtime_error(h5pp::format("Error creating dataset: No dataset path specified"));
               if(not options.dataDims) throw std::runtime_error(h5pp::format("Error creating dataset [{}]: Dimensions or size not specified", options.linkPath.value()));
               if(not options.h5Type) throw std::runtime_error(h5pp::format("Error creating dataset [{}]: HDF5 type not specified", options.linkPath.value()));
               auto dsetInfo = h5pp::scan::getDsetInfo(openFileHandle(), options, plists);
               h5pp::File::createDataset(dsetInfo);
               return dsetInfo;
           }
   
           DsetInfo createDataset(std::optional<hid::h5t>     h5Type,
                                  std::string_view            dsetPath,
                                  const DimsType &            dsetDims,
                                  std::optional<H5D_layout_t> h5Layout     = std::nullopt,
                                  const OptDimsType &         dsetDimsChunk = std::nullopt,
                                  const OptDimsType &         dsetDimsMax   = std::nullopt,
                                  std::optional<unsigned int> compression   = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create dataset on read-only file [{}]", filePath.string()));
               Options options;
               options.linkPath      = dsetPath;
               options.dataDims      = dsetDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Type        = std::move(h5Type);
               options.h5Layout      = h5Layout;
               options.compression   = getCompressionLevel(compression);
               return createDataset(options);
           }
   
           template<typename DataType>
           DsetInfo createDataset(const DataType &data, const Options &options) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create dataset on read-only file [{}]", filePath.string()));
               auto dsetInfo = h5pp::scan::getDsetInfo(openFileHandle(), data, options, plists);
               h5pp::File::createDataset(dsetInfo);
               return dsetInfo;
           }
   
           template<typename DataType>
           DsetInfo createDataset(const DataType &            data,
                                  std::string_view            dsetPath,
                                  const OptDimsType &         dataDims      = std::nullopt,
                                  std::optional<H5D_layout_t> h5Layout     = std::nullopt,
                                  const OptDimsType &         dsetDimsChunk = std::nullopt,
                                  const OptDimsType &         dsetDimsMax   = std::nullopt,
                                  std::optional<unsigned int> compression   = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create dataset on read-only file [{}]", filePath.string()));
               Options options;
               options.linkPath      = dsetPath;
               options.dataDims      = dataDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Type        = h5pp::util::getH5Type<DataType>();
               options.h5Layout      = h5Layout;
               options.compression   = getCompressionLevel(compression);
               // If dsetdims is a nullopt we can infer its dimensions from the given dataset
               return createDataset(data, options);
           }
   
           template<typename DataType>
           void writeDataset(const DataType &data, DsetInfo &dsetInfo, const Options &options = Options()) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               if(not dsetInfo.dsetExists or not dsetInfo.dsetExists.value()) createDataset(dsetInfo);
               auto dataInfo = h5pp::scan::getDataInfo(data,options);
               resizeDataset(dsetInfo, dataInfo.dataDims.value());
               h5pp::hdf5::writeDataset(data, dataInfo, dsetInfo, plists);
           }
   
           template<typename DataType>
           void writeDataset(const DataType &data, const DataInfo &dataInfo, DsetInfo &dsetInfo) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               // The infos passed should be parsed and ready to write with
               if(not dsetInfo.dsetExists or not dsetInfo.dsetExists.value()) createDataset(dsetInfo);
               resizeDataset(dsetInfo, dataInfo.dataDims.value());
               h5pp::hdf5::writeDataset(data, dataInfo, dsetInfo, plists);
           }
   
           template<typename DataType>
           DsetInfo writeDataset(const DataType &data, const Options &options) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               options.assertWellDefined();
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               auto dsetInfo = h5pp::scan::getDsetInfo(openFileHandle(), data, options, plists); // Creates if it doesn't exist, otherwise it just fills the meta data
               writeDataset(data, dataInfo, dsetInfo);
               return dsetInfo;
           }
   
           template<typename DataType>
           DsetInfo writeDataset(const DataType &            data,                     
                                 std::string_view            dsetPath,                 
                                 const OptDimsType &         dataDims  = std::nullopt, 
                                 std::optional<H5D_layout_t> h5Layout = std::nullopt, 
                                 const OptDimsType &         dsetDimsChunk = std::nullopt, 
                                 const OptDimsType &         dsetDimsMax   = std::nullopt, 
                                 std::optional<hid::h5t>     h5Type        = std::nullopt, 
                                 std::optional<ResizeMode>   resizeMode    = std::nullopt, 
                                 std::optional<unsigned int> compression = std::nullopt) 
           {
               Options options;
               options.linkPath      = dsetPath;
               options.dataDims      = dataDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Layout      = h5Layout;
               options.h5Type        = std::move(h5Type);
               options.resizeMode    = resizeMode;
               options.compression   = getCompressionLevel(compression);
               return writeDataset(data, options);
           }
   
           template<typename DataType>
           DsetInfo writeDataset(const DataType &            data,                     
                                 std::string_view            dsetPath,                 
                                 hid::h5t &                  h5Type,                   
                                 const OptDimsType &         dataDims  = std::nullopt, 
                                 std::optional<H5D_layout_t> h5Layout = std::nullopt, 
                                 const OptDimsType &         dsetDimsChunk = std::nullopt, 
                                 const OptDimsType &         dsetDimsMax   = std::nullopt, 
                                 std::optional<ResizeMode>   resizeMode    = std::nullopt, 
                                 std::optional<unsigned int> compression = std::nullopt) 
           {
               Options options;
               options.linkPath      = dsetPath;
               options.dataDims      = dataDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Layout      = h5Layout;
               options.h5Type        = h5Type;
               options.resizeMode    = resizeMode;
               options.compression   = getCompressionLevel(compression);
               return writeDataset(data, options);
           }
   
           template<typename DataType>
           DsetInfo writeDataset(const DataType &            data,      
                                 std::string_view            dsetPath,  
                                 H5D_layout_t                h5Layout,  
                                 const OptDimsType &         dataDims      = std::nullopt, 
                                 const OptDimsType &         dsetDimsChunk = std::nullopt, 
                                 const OptDimsType &         dsetDimsMax   = std::nullopt, 
                                 std::optional<hid::h5t>     h5Type        = std::nullopt, 
                                 std::optional<ResizeMode>   resizeMode    = std::nullopt, 
                                 std::optional<unsigned int> compression = std::nullopt) 
           {
               Options options;
               options.linkPath      = dsetPath;
               options.dataDims      = dataDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Layout      = h5Layout;
               options.h5Type        = std::move(h5Type);
               options.resizeMode    = resizeMode;
               options.compression   = getCompressionLevel(compression);
               return writeDataset(data, options);
           }
   
           template<typename DataType>
           DsetInfo writeDataset_compact(const DataType &data, std::string_view dsetPath, const OptDimsType &dataDims = std::nullopt, std::optional<hid::h5t> h5Type = std::nullopt) {
               Options options;
               options.linkPath    = dsetPath;
               options.dataDims    = dataDims;
               options.h5Layout    = H5D_COMPACT;
               options.h5Type      = std::move(h5Type);
               options.compression = 0;
               return writeDataset(data, options);
           }
   
           template<typename DataType>
           DsetInfo
               writeDataset_contiguous(const DataType &data, std::string_view dsetPath, const OptDimsType &dataDims = std::nullopt, std::optional<hid::h5t> h5Type = std::nullopt) {
               Options options; // Get optional iterable should have three different return states, nullopt, empty or nonempty, ´,
               options.linkPath    = dsetPath;
               options.dataDims    = dataDims;
               options.h5Layout    = H5D_CONTIGUOUS;
               options.h5Type      = std::move(h5Type);
               options.compression = 0;
               return writeDataset(data, options);
           }
   
           template<typename DataType>
           DsetInfo writeDataset_chunked(const DataType &            data,
                                         std::string_view            dsetPath,
                                         const OptDimsType &         dataDims      = std::nullopt,
                                         const OptDimsType &         dsetDimsChunk = std::nullopt,
                                         const OptDimsType &         dsetDimsMax   = std::nullopt,
                                         std::optional<hid::h5t>     h5Type        = std::nullopt,
                                         std::optional<unsigned int> compression   = std::nullopt) {
               Options options; // Get optional iterable should have three different return states, nullopt, empty or nonempty, ´,
               options.linkPath      = dsetPath;
               options.dataDims      = dataDims;
               options.dsetDimsChunk = dsetDimsChunk;
               options.dsetDimsMax   = dsetDimsMax;
               options.h5Layout      = H5D_CHUNKED;
               options.h5Type        = std::move(h5Type);
               options.compression   = getCompressionLevel(compression);
               return writeDataset(data, options);
           }
   
           void writeSymbolicLink(std::string_view src_path, std::string_view tgt_path) {
               hid::h5f file = openFileHandle();
               h5pp::hdf5::writeSymbolicLink(file, src_path, tgt_path, plists);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           void readDataset(DataType &data, const DataInfo &dataInfo, const DsetInfo &dsetInfo) const {
               h5pp::hdf5::readDataset(data, dataInfo, dsetInfo, plists);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           DataType readDataset(const DataInfo &dataInfo, const DsetInfo &dsetInfo) const {
               DataType data;
               readDataset(data, dataInfo, dsetInfo);
               return data;
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           void readDataset(DataType &data, const DsetInfo &dsetInfo, const Options &options = Options()) const {
               h5pp::hdf5::resizeData(data, dsetInfo);
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               readDataset(data, dataInfo, dsetInfo);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           DataType readDataset(DsetInfo &dsetInfo, const Options &options = Options()) const {
               DataType data;
               readDataset(data, dsetInfo, options);
               return data;
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           DataType readDataset(DsetInfo &dsetInfo, const DimsType &dataDims) const {
               DataType data;
               Options  options;
               options.dataDims = dataDims;
               readDataset(data, dsetInfo, options);
               return data;
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           void readDataset(DataType &data, const Options &options) const {
               options.assertWellDefined();
               auto dsetInfo = h5pp::scan::readDsetInfo(openFileHandle(), options, plists);
               if(dsetInfo.dsetExists and not dsetInfo.dsetExists.value())
                   throw std::runtime_error(h5pp::format("Cannot read dataset [{}]: It does not exist", options.linkPath.value()));
   
               h5pp::hdf5::resizeData(data, dsetInfo);
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               h5pp::hdf5::readDataset(data, dataInfo, dsetInfo, plists);
           }
   
           template<typename DataType>
           void readDataset(DataType &data, std::string_view dsetPath, const OptDimsType &dataDims = std::nullopt) const {
               Options options;
               options.linkPath = dsetPath;
               options.dataDims = dataDims;
               readDataset(data, options);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           DataType readDataset(std::string_view datasetPath, const OptDimsType &dataDims = std::nullopt) const {
               DataType data;
               readDataset(data, datasetPath, dataDims);
               return data;
           }
   
           template<typename DataType>
           void appendToDataset(DataType &data, const DataInfo &dataInfo, DsetInfo &dsetInfo, size_t axis) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               h5pp::hdf5::extendDataset(dsetInfo, dataInfo, axis);
               h5pp::hdf5::writeDataset(data, dataInfo, dsetInfo, plists);
           }
   
           template<typename DataType>
           void appendToDataset(DataType &data, DsetInfo &dsetInfo, size_t axis, const OptDimsType &dataDims = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               Options options;
               options.dataDims = dataDims;
               auto dataInfo    = h5pp::scan::getDataInfo(data, options);
               appendToDataset(data, dataInfo, dsetInfo, axis);
           }
   
           template<typename DataType>
           DsetInfo appendToDataset(DataType &data, size_t axis, const Options &options = Options()) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               options.assertWellDefined();
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               auto dsetInfo = h5pp::scan::readDsetInfo(openFileHandle(), options, plists);
               appendToDataset(data, dataInfo, dsetInfo, axis);
               return dsetInfo;
           }
   
           template<typename DataType>
           DsetInfo appendToDataset(DataType &data, std::string_view dsetPath, size_t axis, const OptDimsType &dataDims = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               Options options;
               options.linkPath = dsetPath;
               options.dataDims = dataDims;
               return appendToDataset(data, axis, options);
           }
   
           /*
            *
            * Functions related to attributes
            *
            */
   
           void createAttribute(AttrInfo &attrInfo) { h5pp::hdf5::createAttribute(attrInfo); }
   
           template<typename DataType>
           AttrInfo createAttribute(const DataType &data, const Options &options) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to create attribute on read-only file [{}]", filePath.string()));
               auto attrInfo = h5pp::scan::getAttrInfo(openFileHandle(), data, options, plists);
               createAttribute(attrInfo);
               return attrInfo;
           }
   
           template<typename DataType>
           void createAttribute(const DataType &data, const DimsType &dataDims, std::string_view attrName, std::string_view linkPath) {
               Options options;
               options.linkPath = linkPath;
               options.attrName = attrName;
               options.dataDims = dataDims;
               createAttribute(data, options);
           }
   
           template<typename DataType>
           void writeAttribute(const DataType &data, const Options &options) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               options.assertWellDefined();
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               auto attrInfo = createAttribute(data, options);
               h5pp::hdf5::writeAttribute(data, dataInfo, attrInfo);
           }
   
           template<typename DataType>
           void writeAttribute(const DataType &        data,
                               std::string_view        attrName,
                               std::string_view        linkPath,
                               const OptDimsType &     dataDims = std::nullopt,
                               std::optional<hid::h5t> h5Type   = std::nullopt) {
               Options options;
               options.linkPath = linkPath;
               options.attrName = attrName;
               options.dataDims = dataDims;
               options.h5Type   = std::move(h5Type);
               writeAttribute(data, options);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           void readAttribute(DataType &data, const Options &options) const {
               options.assertWellDefined();
               auto attrInfo = h5pp::scan::readAttrInfo(openFileHandle(), options, plists);
               if(attrInfo.linkExists and not attrInfo.linkExists.value())
                   throw std::runtime_error(h5pp::format("Could not read attribute [{}] in link [{}]: "
                                                         "Link does not exist",
                                                         attrInfo.attrName.value(),
                                                         attrInfo.linkPath.value()));
   
               if(attrInfo.attrExists and not attrInfo.attrExists.value())
                   throw std::runtime_error(h5pp::format("Could not read attribute [{}] in link [{}]: "
                                                         "Attribute does not exist",
                                                         attrInfo.attrName.value(),
                                                         attrInfo.linkPath.value()));
   
               h5pp::hdf5::resizeData(data, attrInfo);
               auto dataInfo = h5pp::scan::getDataInfo(data, options);
               h5pp::hdf5::readAttribute(data, dataInfo, attrInfo);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           void readAttribute(DataType &data, std::string_view attrName, std::string_view linkPath, const OptDimsType &dataDims = std::nullopt) const {
               Options options;
               options.linkPath = linkPath;
               options.attrName = attrName;
               options.dataDims = dataDims;
               readAttribute(data, options);
           }
   
           template<typename DataType, typename = std::enable_if_t<not std::is_const_v<DataType>>>
           [[nodiscard]] DataType readAttribute(std::string_view attrName, std::string_view linkPath, const OptDimsType &dataDims = std::nullopt) const {
               DataType data;
               readAttribute(data, attrName, linkPath, dataDims);
               return data;
           }
   
           [[nodiscard]] inline std::vector<std::string> getAttributeNames(std::string_view linkPath) const {
               return h5pp::hdf5::getAttributeNames(openFileHandle(), linkPath, std::nullopt, plists.linkAccess);
           }
   
           /*
            *
            *
            * Functions related to tables
            *
            *
            */
   
           TableInfo createTable(const hid::h5t &                  h5EntryType,
                                 std::string_view                  tableName,
                                 std::string_view                  tableTitle,
                                 const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                 const std::optional<unsigned int> desiredCompressionLevel = std::nullopt
   
           ) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               auto tableInfo = h5pp::scan::newTableInfo(h5EntryType, tableName, tableTitle, desiredChunkSize, desiredCompressionLevel);
               h5pp::hdf5::createTable(openFileHandle(), tableInfo, plists);
               return tableInfo;
           }
   
           template<typename DataType>
           TableInfo appendTableEntries(const DataType &data, std::string_view tableName) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               auto info = h5pp::scan::getTableInfo(openFileHandle(), tableName, std::nullopt, plists);
               if(not info.tableExists.value()) throw std::runtime_error(h5pp::format("Cannot append to table [{}]: it does not exist", tableName));
               h5pp::hdf5::appendTableEntries(data, info);
               return info;
           }
   
           void addTableEntriesFrom(const h5pp::TableInfo &           srcInfo,
                                    h5pp::TableInfo &                 tgtInfo,
                                    TableSelection                    tableSelection,
                                    const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                    const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               if(not srcInfo.tableExists) throw std::runtime_error("Source table info has not been initialized");
               if(not srcInfo.tableExists.value()) throw std::runtime_error("Source table does not exist");
               if(not tgtInfo.tableExists or not tgtInfo.tableExists.value())
                   tgtInfo = createTable(srcInfo.tableType.value(), tgtInfo.tablePath.value(), srcInfo.tableTitle.value(), desiredChunkSize, desiredCompressionLevel);
               hsize_t srcStartEntry = 0;
               hsize_t tgtStartEntry = 0;
               hsize_t numEntries    = 0;
               switch(tableSelection) {
                   case h5pp::TableSelection::ALL: numEntries = srcInfo.numRecords.value(); break;
                   case h5pp::TableSelection::FIRST:
                       numEntries = 1;
                       if(tgtInfo.numRecords.value() > 0) tgtStartEntry = tgtInfo.numRecords.value() - 1;
                       break;
                   case h5pp::TableSelection::LAST:
                       numEntries = 1;
                       if(tgtInfo.numRecords.value() > 0) tgtStartEntry = tgtInfo.numRecords.value() - 1;
                       if(srcInfo.numRecords.value() > 0) srcStartEntry = srcInfo.numRecords.value() - 1;
                       break;
               }
               h5pp::hdf5::addTableEntriesFrom(srcInfo, tgtInfo, srcStartEntry, tgtStartEntry, numEntries);
           }
   
           TableInfo addTableEntriesFrom(const h5pp::TableInfo &           srcInfo,
                                         std::string_view                  tgtTableName,
                                         TableSelection                    tableSelection,
                                         const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                         const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               auto tgtInfo = h5pp::scan::getTableInfo(openFileHandle(), tgtTableName, std::nullopt, plists);
               addTableEntriesFrom(srcInfo, tgtInfo, tableSelection, desiredChunkSize, desiredCompressionLevel);
               return tgtInfo;
           }
   
           template<typename h5x_src, typename = h5pp::type::sfinae::enable_if_is_h5_loc<h5x_src>>
           TableInfo addTableEntriesFrom(const h5x_src &                   srcLocation,
                                         std::string_view                  srcTableName,
                                         std::string_view                  tgtTableName,
                                         TableSelection                    tableSelection,
                                         const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                         const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               auto srcInfo = h5pp::scan::getTableInfo(srcLocation, srcTableName, std::nullopt, plists);
               return addTableEntriesFrom(srcInfo, tgtTableName, tableSelection, desiredChunkSize, desiredCompressionLevel);
           }
   
           void addTableEntriesFrom(const h5pp::TableInfo &           srcInfo,
                                    h5pp::TableInfo &                 tgtInfo,
                                    hsize_t                           srcStartEntry,
                                    hsize_t                           tgtStartEntry,
                                    hsize_t                           numEntries,
                                    const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                    const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               if(permission == h5pp::FilePermission::READONLY) throw std::runtime_error(h5pp::format("Attempted to write on read-only file [{}]", filePath.string()));
               if(not srcInfo.tableExists) throw std::runtime_error("Source table info has not been initialized");
               if(not srcInfo.tableExists.value()) throw std::runtime_error("Source table does not exist");
               if(not tgtInfo.tableExists.value())
                   tgtInfo = createTable(srcInfo.tableType.value(), tgtInfo.tablePath.value(), srcInfo.tableTitle.value(), desiredChunkSize, desiredCompressionLevel);
               h5pp::hdf5::addTableEntriesFrom(srcInfo, tgtInfo, srcStartEntry, tgtStartEntry, numEntries);
           }
   
           template<typename h5x_src, typename = h5pp::type::sfinae::enable_if_is_h5_loc<h5x_src>>
           TableInfo addTableEntriesFrom(const h5pp::TableInfo &           srcInfo,
                                         std::string_view                  tgtTableName,
                                         hsize_t                           srcStartEntry,
                                         hsize_t                           tgtStartEntry,
                                         hsize_t                           numEntries,
                                         const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                         const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               auto tgtInfo = h5pp::scan::getTableInfo(openFileHandle(), tgtTableName, std::nullopt, plists);
               addTableEntriesFrom(srcInfo, tgtInfo, srcStartEntry, tgtStartEntry, numEntries, desiredChunkSize, desiredCompressionLevel);
               return tgtInfo;
           }
   
           template<typename h5x_src, typename = h5pp::type::sfinae::enable_if_is_h5_loc<h5x_src>>
           TableInfo addTableEntriesFrom(const h5x_src &                   srcLocation,
                                         std::string_view                  srcTableName,
                                         std::string_view                  tgtTableName,
                                         hsize_t                           srcStartIdx,
                                         hsize_t                           tgtStartIdx,
                                         hsize_t                           numRecords,
                                         const std::optional<hsize_t>      desiredChunkSize        = std::nullopt,
                                         const std::optional<unsigned int> desiredCompressionLevel = std::nullopt) {
               auto srcInfo = h5pp::scan::getTableInfo(srcLocation, srcTableName, std::nullopt, plists);
               return addTableEntriesFrom(srcInfo, tgtTableName, srcStartIdx, tgtStartIdx, numRecords, desiredChunkSize, desiredCompressionLevel);
           }
   
           template<typename DataType>
           void readTableEntries(DataType &data, std::string_view tableName, std::optional<size_t> startEntry = std::nullopt, std::optional<size_t> numEntries = std::nullopt) const {
               auto info = h5pp::scan::getTableInfo(openFileHandle(), tableName, std::nullopt, plists);
               h5pp::hdf5::readTableEntries(data, info, startEntry, numEntries);
           }
   
           template<typename DataType>
           DataType readTableEntries(std::string_view tablePath, std::optional<size_t> startEntry = std::nullopt, std::optional<size_t> numEntries = std::nullopt) const {
               DataType data;
               readTableEntries(data, tablePath, startEntry, numEntries);
               return data;
           }
   
           template<typename DataType>
           void readTableField(DataType &            data,
                               std::string_view      tablePath,
                               std::string_view      fieldNames,
                               std::optional<size_t> startEntry = std::nullopt,
                               std::optional<size_t> numEntries = std::nullopt) const {
               auto info = h5pp::scan::getTableInfo(openFileHandle(), tablePath, std::nullopt, plists);
               h5pp::hdf5::readTableField(data, info, fieldNames, startEntry, numEntries);
           }
   
           template<typename DataType>
           DataType readTableField(std::string_view      tablePath,
                                   std::string_view      fieldName,
                                   std::optional<size_t> startEntry = std::nullopt,
                                   std::optional<size_t> numEntries = std::nullopt) const {
               DataType data;
               readTableField(data, tablePath, fieldName, startEntry, numEntries);
               return data;
           }
   
           template<typename DataType>
           void readTableField(DataType &data, std::string_view tablePath, std::string_view fieldNames, TableSelection tableSelection) const {
               auto    info       = h5pp::scan::getTableInfo(openFileHandle(), tablePath, std::nullopt, plists);
               hsize_t startEntry = 0;
               hsize_t numEntries = 0;
               switch(tableSelection) {
                   case h5pp::TableSelection::ALL:
                       startEntry = 0;
                       numEntries = info.numRecords.value();
                       break;
                   case h5pp::TableSelection::FIRST:
                       startEntry = 0;
                       numEntries = 1;
                       break;
                   case h5pp::TableSelection::LAST:
                       startEntry = info.numRecords.value() - 1;
                       numEntries = 1;
                       break;
               }
               h5pp::hdf5::readTableField(data, info, fieldNames, startEntry, numEntries);
           }
   
           template<typename DataType>
           DataType readTableField(std::string_view tablePath, std::string_view fieldName, TableSelection tableSelection) const {
               DataType data;
               readTableField(data, tablePath, fieldName, tableSelection);
               return data;
           }
   
           /*
            *
            *
            * Functions for querying
            *
            *
            */
   
           [[nodiscard]] int getDatasetRank(std::string_view datasetPath) const {
               auto dataset = h5pp::hdf5::openLink<hid::h5d>(openFileHandle(), datasetPath);
               return h5pp::hdf5::getRank(dataset);
           }
   
           [[nodiscard]] std::vector<hsize_t> getDatasetDimensions(std::string_view datasetPath) const {
               auto dataset = h5pp::hdf5::openLink<hid::h5d>(openFileHandle(), datasetPath);
               return h5pp::hdf5::getDimensions(dataset);
           }
           [[nodiscard]] std::optional<std::vector<hsize_t>> getDatasetMaxDimensions(std::string_view datasetPath) const {
               auto dataset = h5pp::hdf5::openLink<hid::h5d>(openFileHandle(), datasetPath);
               return h5pp::hdf5::getMaxDimensions(dataset);
           }
   
           [[nodiscard]] std::optional<std::vector<hsize_t>> getDatasetChunkDimensions(std::string_view datasetPath) const {
               auto dataset = h5pp::hdf5::openLink<hid::h5d>(openFileHandle(), datasetPath);
               return h5pp::hdf5::getChunkDimensions(dataset);
           }
   
           [[nodiscard]] bool linkExists(std::string_view link) const { return h5pp::hdf5::checkIfLinkExists(openFileHandle(), link, std::nullopt, plists.linkAccess); }
   
   //        [[nodiscard]] std::vector<std::string> getLinks(std::string_view root = "/", long maxDepth = 0) const {
   //            return h5pp::hdf5::getContentsOfLink<H5O_type_t::H5O_TYPE_UNKNOWN>(openFileHandle(), root, maxDepth, plists.linkAccess);
   //        }
   //
   //        [[nodiscard]] std::vector<std::string> getDatasets(std::string_view root = "/", long maxDepth = 0) const {
   //            return h5pp::hdf5::getContentsOfLink<H5O_type_t::H5O_TYPE_DATASET>(openFileHandle(), root, maxDepth, plists.linkAccess);
   //        }
   //
   //        [[nodiscard]] std::vector<std::string> getGroups(std::string_view root = "/", long maxDepth = 0) const {
   //            return h5pp::hdf5::getContentsOfLink<H5O_type_t::H5O_TYPE_GROUP>(openFileHandle(), root, maxDepth, plists.linkAccess);
   //        }
   
           [[nodiscard]] std::vector<std::string> findLinks(std::string_view searchKey = "", std::string_view searchRoot = "/", long maxHits = -1, long maxDepth = -1) const {
               return h5pp::hdf5::findLinks<H5O_TYPE_UNKNOWN>(openFileHandle(), searchKey, searchRoot, maxHits, maxDepth, plists.linkAccess);
           }
   
           [[nodiscard]] std::vector<std::string> findDatasets(std::string_view searchKey = "", std::string_view searchRoot = "/", long maxHits = -1, long maxDepth = -1) const {
               return h5pp::hdf5::findLinks<H5O_TYPE_DATASET>(openFileHandle(), searchKey, searchRoot, maxHits, maxDepth, plists.linkAccess);
           }
   
           [[nodiscard]] std::vector<std::string> findGroups(std::string_view searchKey = "", std::string_view searchRoot = "/", long maxHits = -1, long maxDepth = -1) const {
               return h5pp::hdf5::findLinks<H5O_TYPE_GROUP>(openFileHandle(), searchKey, searchRoot, maxHits, maxDepth, plists.linkAccess);
           }
   
           [[nodiscard]] DsetInfo getDatasetInfo(std::string_view dsetPath) const {
               Options options;
               options.linkPath = h5pp::util::safe_str(dsetPath);
               return h5pp::scan::readDsetInfo(openFileHandle(), options, plists);
           }
   
           [[nodiscard]] AttrInfo getAttributeInfo(std::string_view linkPath, std::string_view attrName) const {
               Options options;
               options.linkPath = h5pp::util::safe_str(linkPath);
               options.attrName = h5pp::util::safe_str(attrName);
               return h5pp::scan::readAttrInfo(openFileHandle(), options, plists);
           }
   
           [[nodiscard]] TableInfo getTableInfo(std::string_view tablePath) const { return h5pp::scan::getTableInfo(openFileHandle(), tablePath, std::nullopt, plists); }
   
           [[nodiscard]] TypeInfo getTypeInfoDataset(std::string_view dsetPath) const { return h5pp::hdf5::getTypeInfo(openFileHandle(), dsetPath, std::nullopt, plists.linkAccess); }
   
           [[nodiscard]] TypeInfo getTypeInfoAttribute(std::string_view linkPath, std::string_view attrName) const {
               return h5pp::hdf5::getTypeInfo(openFileHandle(), linkPath, attrName, std::nullopt, std::nullopt, plists.linkAccess);
           }
   
           [[nodiscard]] std::vector<TypeInfo> getTypeInfoAttributes(std::string_view linkPath) const {
               return h5pp::hdf5::getTypeInfo_allAttributes(openFileHandle(), linkPath, std::nullopt, plists.linkAccess);
           }
   
           [[nodiscard]] bool fileIsValid() const { return h5pp::hdf5::fileIsValid(filePath); }
       };
   }